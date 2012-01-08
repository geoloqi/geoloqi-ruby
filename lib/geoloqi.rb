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
    def api_version
      1
    end

    def api_url
      'https://api.geoloqi.com'
    end

    def oauth_url
      'https://geoloqi.com/oauth/authorize'
    end

    def config(opts=nil)
      return @@config if opts.nil?
      @@config = Config.new opts
    end

    def get(access_token, path, args={}, headers={})
      run :get, access_token, path, args, headers
    end

    def post(access_token, path, args={}, headers={})
      run :post, access_token, path, args, headers
    end

    def run(meth, access_token, path, args={}, headers={})
      Session.new(:access_token => access_token).run meth, path, args, headers
    end

    def authorize_url(client_id=nil, redirect_uri=@@config.redirect_uri, opts={})
      raise "client_id required to authorize url. Pass with Geoloqi.config" unless client_id
      url = "#{oauth_url}?response_type=code&client_id=#{Rack::Utils.escape client_id}&redirect_uri=#{Rack::Utils.escape redirect_uri}"
      url += "&#{Rack::Utils.build_query opts}" unless opts.empty?
      url
    end
  end
end
