module Geoloqi
  class Config
    # OAuth2 Client ID for the application. Retrieve from the Geoloqi Developers Site.
    #
    # @return [String]
    # @example
    #  Geoloqi.config.client_id = 'YOUR APPLICATION CLIENT ID'
    attr_accessor :client_id
    
    # OAuth2 Client Secret for the application. Retrieve from the Geoloqi Developers Site.
    # @return [String]
    attr_accessor :client_secret
    
    # OAuth2 Redirect URI. This is the location the user will be redirected to after authorization from the Geoloqi OAuth2 server.
    # If this is not provided, the user will be redirected to the URI configured at the Geoloqi Developers Site.
    # @return [String]
    attr_accessor :redirect_uri
    
    # Which HTTP adapter to use for Faraday. Defaults to :net_http
    #
    # @return [Symbol]
    # @example
    #  Geoloqi.config.adapter = :typhoeus
    attr_accessor :adapter
    
    # Provide a logger. This can be any object that responds to print and puts (anything that inherits IO).
    #
    # @return [IO]
    # @example
    #  Geoloqi.config.logger = STDOUT
    attr_accessor :logger
    
    # Use Hashie::Mash for return objects, which provides dot-style data retrieval.
    #
    # @see https://github.com/intridea/hashie
    # @return [Boolean]
    # @example
    #  Geoloqi.config.use_hashie_mash = true
    #   
    #   # Get profile and retrieve data via Hashie::Mash dot notation
    #   result = Geoloqi.get 'YOUR ACCESS TOKEN', 'account/profile'
    #   result.name # => "Your Name"
    attr_accessor :use_hashie_mash
    
    # Throw Geoloqi::ApiError exception on API errors. Defaults to true. If set to false, you will need to check for the error key in responses.
    #
    # @return [Boolean]
    # @example
    #  Geoloqi.config.throw_exceptions = false
    attr_accessor :throw_exceptions
    
    # Use dynamic error class names, which inherit from Geoloqi::ApiError. This may be deprecated in a future release.
    #
    # @return [Boolean]
    attr_accessor :use_dynamic_exceptions
    
    # Use symbols for keys in Hash response. Defaults to true.
    #
    # @return [Boolean]
    # @example
    #  Geoloqi.config.symbolize_names = true
    attr_accessor :symbolize_names


    # Instantiate a new Geoloqi::Config object.
    #
    # @param opts A hash of the config settings.
    # @return [Config]
    # @example
    #  # Dynamically create a Geoloqi::Config object
    #  geoloqi_config = Geoloqi::Config.new :use_hashie_mash => true, :throw_exceptions => false
    #
    #  # Use geoloqi_config to create new session
    #  geoloqi_session = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN', :config => geoloqi_config
    def initialize(opts={})
      self.use_hashie_mash ||= false
      self.throw_exceptions ||= true
      self.symbolize_names ||= true
      self.use_dynamic_exceptions ||= false

      opts.each {|k,v| send("#{k}=", v)}

      begin
        require 'hashie' if self.use_hashie_mash && !defined?(Hashie::Mash)
      rescue LoadError
        raise Error, "You've requested Hashie::Mash, but the gem is not available. Don't set use_hashie_mash in your config, or install the hashie gem"
      end
    end

    # Check if the OAuth2 Client ID exists.
    # @return [Boolean]
    def client_id?
      !client_id.nil? && !client_id.empty?
    end

    # Check if OAuth2 Client Secret exists.
    # @return [Boolean]
    def client_secret?
      !client_secret.nil? && !client_secret.empty?
    end
  end
end