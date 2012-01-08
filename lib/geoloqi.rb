libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
require 'json'
require 'faraday'
require 'logger'
require 'geoloqi/config'
require 'geoloqi/error'
require 'geoloqi/response'
require 'geoloqi/session'
require 'geoloqi/version'

module Geoloqi
  SSL_CERT_FILE = File.join(File.dirname(__FILE__), 'geoloqi/data/ca-certificates.crt')
  @@config = Config.new

  class << self
    # Which API version to use.
    #
    # @return [Fixnum]
    def api_version
      1
    end

    # API URL for the Geoloqi Platform.
    #
    # @return [String]
    def api_url
      'https://api.geoloqi.com'
    end

    # OAuth2 authorize URL for the Geoloqi Platform.
    #
    # @return [String]
    def oauth_url
      'https://geoloqi.com/oauth/authorize'
    end

    # Global config object accessor, which is used for Geoloqi.get/post. Geoloqi::Session inherits this config by default.
    #
    # @return [Geoloqi::Config]
    # @example
    #  # Setup the OAuth2 id/secret and use Hashie::Mash for output.
    #  Geoloqi.config :client_id => 'CLIENT ID', :client_secret => 'CLIENT SECRET', :use_hashie_mash => true
    def config(opts=nil)
      return @@config if opts.nil?
      @@config = Config.new opts
    end

    # Makes a one-time GET request to the Geoloqi API. You can retreive your access token from the Geoloqi Developers Site.
    #
    # @return [Hash]
    # @example
    #  # Get your user profile
    #  Geoloqi.get 'YOUR_ACCESS_TOKEN', 'account/profile'
    #
    #  # Get the last 5 locations
    #  Geoloqi.get 'YOUR_ACCESS_TOKEN', 'account/profile', :count => 5
    def get(access_token, path, args={}, headers={})
      run :get, access_token, path, args, headers
    end

    # Makes a one-time POST request to the Geoloqi API. You can retreive your access token from the Geoloqi Developers Site.
    #
    # @return [Hash] by default, [Hashie::Mash] if <tt>:use_hashie_mash</tt> is true in the config.
    # @example
    #  # Create a new layer
    #  Geoloqi.post 'YOUR_ACCESS_TOKEN', 'layer/create', :name => 'Northeast Portland'
    def post(access_token, path, args={}, headers={})
      run :post, access_token, path, args, headers
    end

    # Makes a one-time request to the Geoloqi API. You can retreive your access token from the Geoloqi Developers Site.
    #
    # @return [Hash] by default, [Hashie::Mash] if <tt>:use_hashie_mash</tt> is true in the config.
    # @example
    #  # Retrieve your profile
    #  Geoloqi.run :get, 'YOUR_ACCESS_TOKEN', 'account/profile'
    def run(meth, access_token, path, args={}, headers={})
      Session.new(:access_token => access_token).run meth, path, args, headers
    end

    # Returns the OAuth2 authorize url.
    # 
    # @return [String]
    # @example
    #   Geoloqi.authorize_url 'YOUR_CLIENT_ID'
    def authorize_url(client_id=nil, redirect_uri=@@config.redirect_uri, opts={})
      raise "client_id required to authorize url. Pass with Geoloqi.config" unless client_id
      url = "#{oauth_url}?response_type=code&client_id=#{Rack::Utils.escape client_id}&redirect_uri=#{Rack::Utils.escape redirect_uri}"
      url += "&#{Rack::Utils.build_query opts}" unless opts.empty?
      url
    end
  end
end
