require 'thread'

module Geoloqi
  # This class is used to instantiate a session object. It is designed to be thread safe, and multiple sessions can be used
  # simultaneously, allowing for one ruby application to potentially handle multiple Geoloqi applications.
  #
  # @example
  #  # Instantiate a session with your access token (obtained from the Geoloqi Developers Site):
  #  geoloqi_session = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN'
  #
  #  # Instantiate a session with a custom config:
  #  geoloqi_session = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN', :config => {:use_hashie_mash => true}
  #
  #  # Instantiate a session with OAuth2 credentials (obtained from the Geoloqi Developers Site):
  #  geoloqi_session = Geoloqi::Session.new :config => {:client_id => 'CLIENT ID', :client_secret => 'CLIENT SECRET'}
  #
  #  # Get profile:
  #  result = geoloqi_session.get 'account/profile'
  class Session
    # The auth Hash, which is provided by the OAuth2 response. This can be stored externally and used to re-initialize the session.
    # @return [Hash]
    attr_reader :auth

    # The config object attached to this session. It is unique to this session, and can be replaced/changed dynamically.
    # @return [Config]
    attr_accessor :config
    
    # The raw response object for the request. Using this, you can find the HTTP code of the response.
    # For example, geoloqi.response.status
    # The headers are available at geoloqi.response.headers
    # @return [Response]
    attr_reader :response

    # Instantiate a Geoloqi session.
    #
    # @return [Config]
    # @example
    #  # With access token
    #  geoloqi_session = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN'
    #
    #  # With OAuth2
    #  geoloqi_session = Geoloqi::Session.new :config => {:client_id => 'CLIENT ID', :client_secret => 'CLIENT SECRET'}
    def initialize(opts={})
      opts[:config] = Geoloqi::Config.new opts[:config] if opts[:config].is_a? Hash
      @config = opts[:config] || (Geoloqi.config || Geoloqi::Config.new).dup
      self.auth = opts[:auth] || {}
      self.auth[:access_token] = opts[:access_token] if opts[:access_token]

      @connection = Faraday.new(:url => Geoloqi.api_url, :ssl => {:verify => true, :ca_file => Geoloqi::SSL_CERT_FILE}) do |builder|
        builder.adapter  @config.adapter || :net_http
      end
    end

    def auth=(hash)
      new_auth = hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      synchronize { @auth = new_auth }
    end

    # The access token for this session.
    # @return [String]
    def access_token
      @auth[:access_token]
    end

    # Retrieve the application access token for this session.
    # This token is used in the same manner as the user access token, it simply allows the application to make
    # requests on behalf of itself instead of a user within the app.
    # It is strongly recommended that you keep this token private, and don't share it with
    # clients.
    #
    # This call makes a request to the API server for each instantiation of the object (so it will request once per
    # session object, and then cache the result). It is recommended that you cache this
    # with something like memcache to avoid latency issues.
    # @return [String]
    def application_access_token
      @application_access_token ||= establish(:grant_type => 'client_credentials')[:access_token]
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

    # Makes a GET request to the Geoloqi API server with application credentials. The client_id and client_secret are
    # sent via an HTTP Authorize header, as per the OAuth2 spec. Otherwise, this method is equivelant to #get.
    #
    # This is required for API calls which require escalated privileges, such as retreiving user information for a user
    # that is not associated with your current access token (GET user/list/ANOTHER_USERS_ID).
    #
    # If you don't require application privileges, you should use the regular #get method instead.
    # 
    # See the Authorization section of the Geoloqi Platform API documentation for more information.
    #
    # @param [String] path
    #   Path to the resource being requested.
    #
    # @param [String, Hash] query (optional)
    #   A query string or Hash to be appended to the request.
    #
    # @param [Hash] headers (optional)
    #   Adds and overwrites headers in request sent to server.
    #
    # @return [Hash,Hashie::Mash]
    # @see #app_post
    # @see #get
    # @example
    #  # Request user information, for a user not associated with the current user access token.
    #  result = geoloqi_session.app_get 'YOUR ACCESS TOKEN', 'user/list/ANOTHER_USERS_ID'
    def app_get(path, query=nil, headers={})
      app_run :get, path, query, headers
    end

    # Makes a POST request to the Geoloqi API server with application credentials. The client_id and client_secret are
    # sent via an HTTP Authorize header, as per the OAuth2 spec. Otherwise, this method is equivelant to #post.
    #
    # This is required for API calls which require escalated privileges, such as creating a user account (user/create, user/create_anon) 
    # or making a request for an access token (oauth/token).
    #
    # If you don't require application privileges, you should use the regular #post method instead.
    #
    # See the Authorization section of the Geoloqi Platform API documentation for more information.
    #
    # @param [String] path
    #  Path to the resource being requested (example: '/account/profile').
    #
    # @param [String, Hash] query (optional)
    #  A query string or Hash to be converted to POST parameters.
    #
    # @param [Hash] headers (optional)
    #  Adds and overwrites headers in request sent to server.
    #
    # @return [Hash,Hashie::Mash]
    # @see #app_get
    # @see #post
    # @example
    #  # Create a new layer
    #  result = geoloqi_session.post 'layer/create', :name => 'Portland Food Carts'
    def app_post(path, query=nil, headers={})
      app_run :post, path, query, headers
    end

    # Makes a request to the Geoloqi API server with escalated privileges.
    #
    # @return [Hash,Hashie::Mash]
    # @see #app_get
    # @see #app_post
    # @example
    #  # Create a new layer
    #  result = geoloqi_session.run :get, 'layer/create', :name => 'Northeast Portland'
    def app_run(meth, path, query=nil, headers={})
      raise Error, 'client_id and client_secret are required to make application requests' unless @config.client_id? && @config.client_secret?

      credentials = "#{@config.client_id}:#{@config.client_secret}"

      # Base64.strict_encode64 in 1.9, but we're using pack directly for compatibility with 1.8.
      headers['Authorization'] = "Basic " + [credentials].pack("m0")

      run meth, path, query, headers
    end

    # Makes a GET request to the Geoloqi API server and returns response.
    #
    # @param [String] path
    #   Path to the resource being requested.
    #
    # @param [String, Hash] query (optional)
    #   A query string or Hash to be appended to the request.
    #
    # @param [Hash] headers (optional)
    #   Adds and overwrites headers in request sent to server.
    #
    # @return [Hash,Hashie::Mash]
    # @see #app_get
    # @see #post
    # @example
    #  # Get your user profile
    #  result = geoloqi_session.get 'account/profile'
    #
    #  # Get the last 5 locations
    #  result = geoloqi_session.get 'account/profile', :count => 5
    def get(path, query=nil, headers={})
      run :get, path, query, headers
    end

    # Makes a POST request to the Geoloqi API server and returns response.
    #
    # @param [String] path
    #  Path to the resource being requested (example: '/account/profile').
    #
    # @param [String, Hash] query (optional)
    #  A query string or Hash to be converted to POST parameters.
    #
    # @param [Hash] headers (optional)
    #  Adds and overwrites headers in request sent to server.
    #
    # @return [Hash,Hashie::Mash]
    # @see #get
    # @see #app_post
    # @example
    #  # Create a new layer
    #  result = geoloqi_session.post 'layer/create', :name => 'Portland Food Carts'
    def post(path, query=nil, headers={})
      run :post, path, query, headers
    end

    # Makes a request to the Geoloqi API server.
    #
    # @return [Hash,Hashie::Mash]
    # @example
    #  # Create a new layer
    #  result = geoloqi_session.run :get, 'layer/create', :name => 'Northeast Portland'
    def run(meth, path, query=nil, headers={})
      renew_access_token! if auth[:expires_at] && Time.rfc2822(auth[:expires_at]) <= Time.now && !(path =~ /^\/?oauth\/token$/)
      retry_attempt = 0

      begin
        response = execute meth, path, query, headers
        @response = response # Make the response object available to the caller
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

    # Makes a low-level request to the Geoloqi API server. It does no processing of the response.
    #
    # @return [Response]
    # @example
    #  result = geoloqi_session.execute :get, 'account/profile'
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

    # Make a batch request to the Geoloqi API. Compiles POST requests (provided in a block) and returns an array of the results,
    # which includes the response code, headers, and body. Calls are made synchronously on the server, and the results are returned in
    # the same order. This should be much faster for scenarios where inserting/updating hundreds or thousands of records is needed.
    # @return [Array] - An array of Hash objects containing the response code, headers, and body.
    # @see Batch
    # @example
    #  # Create 3 layers at once, return responses in an array
    #  responses_array = geoloqi_session.batch do
    #    post 'layer/create', :name => 'Layer 1'
    #    post 'layer/create', :name => 'Layer 2'
    #    post 'layer/create', :name => 'Layer 3'
    #  end
    def batch(&block)
      Batch.new(self, &block).run!
    end

    # Used to retrieve the access token from the Geoloqi OAuth2 server. This is fairly low level and you shouldn't need to use it directly.
    #
    # @return [Hash] - The auth hash used to persist the session object.
    # @see #renew_access_token!
    # @see #get_auth
    # @see #application_access_token
    def establish(opts={})
      raise Error, 'client_id and client_secret are required to get access token' unless @config.client_id? && @config.client_secret?
      auth = post 'oauth/token', {:client_id     => @config.client_id,
                                  :client_secret => @config.client_secret}.merge!(opts)

      self.auth = auth
      self.auth[:expires_at] = auth_expires_at auth[:expires_in]
      self.auth
    end

    # Renew the access token provided from Geoloqi using the stored refresh token. This method is automatically called by the session object
    # when it detects an expiration, so you shouldn't need to explicitly call it.
    #
    # @return [Hash] The auth hash used to persist the session object.
    # @see #establish
    def renew_access_token!
      establish :grant_type => 'refresh_token', :refresh_token => self.auth[:refresh_token]
    end

    # Get the OAuth2 authentication information. This call also stores the auth to the session automatically.
    #
    # @param code [String] The code provided by the Geoloqi OAuth2 server.
    # @param redirect_uri [String] The redirect URI provided to the Geoloqi OAuth2 server. This value must match the redirect_uri sent to the server.
    # @return [Hash] The auth hash used to persist the session object.
    # @see #establish
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

    # Used to retrieve a semaphore lock for thread safety.
    def synchronize(&block)
      @@semaphore ||= Mutex.new
      @@semaphore.synchronize &block
    end
  end
end
