module Geoloqi
  class Session
    attr_reader :auth
    attr_accessor :config

    def initialize(opts={})
      opts[:config] = Geoloqi::Config.new opts[:config] if opts[:config].is_a? Hash
      @config = opts[:config] || (Geoloqi.config || Geoloqi::Config.new)
      self.auth = opts[:auth] || {}
      self.auth[:access_token] = opts[:access_token] if opts[:access_token]

      @connection = Faraday.new(:url => API_URL) do |builder|
        builder.response :logger if @config.enable_logging
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

    def authorize_url(redirect_uri=@config.redirect_uri)
      Geoloqi.authorize_url @config.client_id, redirect_uri
    end

    def get(path, query=nil)
      run :get, path, query
    end

    def post(path, query=nil)
      run :post, path, query
    end

    def run(meth, path, query=nil)
      renew_access_token! if auth[:expires_at] && Time.rfc2822(auth[:expires_at]) <= Time.now && !(path =~ /^\/?oauth\/token$/)
      retry_attempt = 0

      begin
        response = execute meth, path, query
        hash = JSON.parse response.body
        raise ApiError.new(response.status, hash['error'], hash['error_description']) if hash.is_a?(Hash) && hash['error'] && @config.throw_exceptions
      rescue Geoloqi::ApiError
        raise Error.new('Unable to procure fresh access token from API on second attempt') if retry_attempt > 0
        if hash['error'] == 'expired_token'
          renew_access_token!
          retry_attempt += 1
          retry
        else
          fail
        end
      end
      @config.use_hashie_mash ? Hashie::Mash.new(hash) : hash
    end

    def execute(meth, path, query=nil)
      query = Rack::Utils.parse_query query if query.is_a?(String)
      raw = @connection.send(meth) do |req|
        req.url "/#{API_VERSION.to_s}/#{path.gsub(/^\//, '')}"
        req.headers = headers

        if query
          meth == :get ? req.params = query : req.body = query.to_json
        end
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

    def headers
      headers = {'Content-Type' => 'application/json', 'User-Agent' => "geoloqi-ruby #{Geoloqi.version}", 'Accept' => 'application/json'}
      headers['Authorization'] = "OAuth #{access_token}" if access_token
      headers
    end
  end
end