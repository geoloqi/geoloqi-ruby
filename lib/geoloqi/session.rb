module Geoloqi
  # This class is used to instantiate a session object. It is designed to be thread safe, and multiple sessions can be used simultaneously,
  # allowing for one ruby application to potentially handle multiple Geoloqi applications.
  #
  # @example
  #  # Instantiate a session with your access token (obtained from the Geoloqi Developers Site):
  #  session = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN'
  #
  #  # Instantiate a session with a custom config:
  #  session = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN', :config => {:use_hashie_mash => true}
  #
  #  # Instantiate a session with OAuth2 credentials (obtained from the Geoloqi Developers Site):
  #  session = Geoloqi::Session.new :config => {:client_id => 'CLIENT ID', :client_secret => 'CLIENT SECRET'}
  #
  #  # Get profile:
  #  result = session.get 'account/profile'
  class Session
    # This is the auth Hash, which is provided by the OAuth2 response. This can be stored externally and used to re-initialize the session.
    # @return [Hash]
    attr_reader :auth
    
    # This is the config object attached to this session. It is unique to this session.
    # @return [Geoloqi::Config]
    attr_accessor :config

    def initialize(opts={})
      opts[:config] = Geoloqi::Config.new opts[:config] if opts[:config].is_a? Hash
      @config = opts[:config] || (Geoloqi.config || Geoloqi::Config.new)
      self.auth = opts[:auth] || {}
      self.auth[:access_token] = opts[:access_token] if opts[:access_token]

      @connection = Faraday.new(:url => Geoloqi.api_url, :ssl => {:verify => true, :ca_file => Geoloqi::SSL_CERT_FILE}) do |builder|
        builder.adapter  @config.adapter || :net_http
      end
    end

    def auth=(hash)
      @auth = hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

    # The access token for this session.
    # @return [String]
    def access_token
      @auth[:access_token]
    end

    # Determines if the access token exists.
    # @return [Boolean]
    def access_token?
      !access_token.nil?
    end

    # The authorize url for this session.
    #
    # @return [String]
    def authorize_url(redirect_uri=@config.redirect_uri, opts={})
      Geoloqi.authorize_url @config.client_id, redirect_uri, opts
    end

    # Makes a GET request to the Geoloqi API server and returns response.
    #
    # @param [String] path
    #   Path to the resource being requested (example: '/account/profile').
    #
    # @param [String, Hash] query (optional)
    #   A query string or Hash to be appended to the request.
    #
    # @param [Hash] headers (optional)
    #   Adds and overwrites headers in request sent to server.
    #
    # @return [Hash] by default, [Hashie::Mash] if enabled in config.
    # @example
    #  # Get your user profile
    #  response = session.get 'YOUR ACCESS TOKEN', 'account/profile'
    #
    #  # Get the last 5 locations
    #  response = session.get 'YOUR ACCESS TOKEN', 'account/profile', :count => 5
    def get(path, query=nil, headers={})
      run :get, path, query, headers
    end

    # Makes a POST request to the Geoloqi API server and returns response.
    #
    # @param [String] path
    #   Path to the resource being requested (example: '/account/profile').
    #
    # @param [String, Hash] query (optional)
    #   A query string or Hash to be converted to POST parameters.
    #
    # @param [Hash] headers (optional)
    #   Adds and overwrites headers in request sent to server.
    #
    # @return [Hash] by default, [Hashie::Mash] if enabled in config.
    # @example
    #  # Create a new layer
    #  Geoloqi.post 'YOUR ACCESS TOKEN', 'layer/create', :name => 'Portland Food Carts'
    def post(path, query=nil, headers={})
      run :post, path, query, headers
    end

    # Makes a one-time request to the Geoloqi API server.
    # 
    # @return [Hash] by default, [Hashie::Mash] if enabled in config.
    # @example
    #  # Create a new layer
    #  session.post 'YOUR ACCESS TOKEN', 'layer/create', :name => 'Northeast Portland'
    def run(meth, path, query=nil, headers={})
      renew_access_token! if auth[:expires_at] && Time.rfc2822(auth[:expires_at]) <= Time.now && !(path =~ /^\/?oauth\/token$/)
      retry_attempt = 0

      begin
        response = execute meth, path, query, headers
        hash = JSON.parse response.body, :symbolize_names => @config.symbolize_names

        if hash.is_a?(Hash) && hash[:error] && @config.throw_exceptions
          if @config.use_dynamic_exceptions && !hash[:error].nil? && !hash[:error].empty?
            exception_class_name = hash[:error].gsub(/\W+/, '_').split('_').collect {|w| w.capitalize}.join+'Error'
            Geoloqi.const_set exception_class_name, Class.new(Geoloqi::ApiError) unless Geoloqi.const_defined? exception_class_name
            raise_class = Geoloqi.const_get exception_class_name
          else
            raise_class = ApiError
          end
          raise raise_class.new(response.status, hash[:error], hash[:error_description])
        end
      rescue Geoloqi::ApiError
        raise Error.new('Unable to procure fresh access token from API on second attempt') if retry_attempt > 0
        if hash[:error] == 'expired_token' && !(hash[:error_description] =~ /The auth code expired/)
          renew_access_token!
          retry_attempt += 1
          retry
        else
          fail
        end
      rescue JSON::ParserError
        raise Geoloqi::Error, "API returned invalid JSON. Status: #{response.status} Body: #{response.body}"
      end
      @config.use_hashie_mash ? Hashie::Mash.new(hash) : hash
    end

    def execute(meth, path, query=nil, headers={})
      query = Rack::Utils.parse_query query if query.is_a?(String)
      headers = default_headers.merge! headers

      raw = @connection.send(meth) do |req|
        req.url "/#{Geoloqi.api_version.to_s}/#{path.gsub(/^\//, '')}"
        req.headers = headers
        if query
          meth == :get ? req.params = query : req.body = query.to_json
        end
      end

      if @config.logger
        @config.logger.print "### Geoloqi::Session - #{meth.to_s.upcase} #{path}"
        @config.logger.print "?#{Rack::Utils.build_query query}" unless query.nil?
        @config.logger.puts "\n### Request Headers: #{headers.inspect}"
        @config.logger.puts "### Status: #{raw.status}\n### Headers: #{raw.headers.inspect}\n### Body: #{raw.body}"
      end

      Response.new raw.status, raw.headers, raw.body
    end

    def establish(opts={})
      require 'client_id and client_secret are required to get access token' unless @config.client_id? && @config.client_secret?
      auth = post 'oauth/token', {:client_id => @config.client_id,
                                  :client_secret => @config.client_secret}.merge!(opts)

      # expires_at is likely incorrect. I'm chopping 5 seconds
      # off to allow for a more graceful failover.
      auth['expires_at'] = auth_expires_at auth['expires_in']
      self.auth = auth
      self.auth
    end

    def renew_access_token!
      establish :grant_type => 'refresh_token', :refresh_token => self.auth[:refresh_token]
    end

    def get_auth(code, redirect_uri=@config.redirect_uri)
      establish :grant_type => 'authorization_code', :code => code, :redirect_uri => redirect_uri
    end

    private

    def auth_expires_at(expires_in=nil)
      # expires_at is likely incorrect. I'm chopping 5 seconds
      # off to allow for a more graceful failover.
      expires_in.to_i.zero? ? nil : ((Time.now + expires_in.to_i)-5).rfc2822
    end

    def default_headers
      headers = {'Content-Type' => 'application/json', 'User-Agent' => "geoloqi-ruby #{Geoloqi.version}", 'Accept' => 'application/json'}
      headers['Authorization'] = "OAuth #{access_token}" if access_token
      headers
    end
  end
end
