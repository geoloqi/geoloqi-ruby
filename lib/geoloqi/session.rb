module Geoloqi
  class Session
    attr_reader :auth
    attr_accessor :config
    attr_reader :response

    def initialize(opts={})
      opts[:config] = Geoloqi::Config.new opts[:config] if opts[:config].is_a? Hash
      @config = opts[:config] || (Geoloqi.config || Geoloqi::Config.new)
      self.auth = opts[:auth] || {}
      self.auth[:access_token] = opts[:access_token] if opts[:access_token]

      @connection = Faraday.new(:url => Geoloqi.api_url) do |builder|
        builder.adapter  @config.adapter || :net_http
      end
    end

    def auth=(hash)
      @auth = hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

    def access_token
      @auth[:access_token]
    end

    def access_token?
      !access_token.nil?
    end

    def authorize_url(redirect_uri=@config.redirect_uri, opts={})
      Geoloqi.authorize_url @config.client_id, redirect_uri, opts
    end

    def get(path, query=nil, headers={})
      run :get, path, query, headers
    end

    def post(path, query=nil, headers={})
      run :post, path, query, headers
    end

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
      @response = response # Make the response object available to the caller
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
