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
  API_VERSION = 1
  API_URL = 'https://api.geoloqi.com'
  OAUTH_URL = 'https://beta.geoloqi.com/oauth/authorize'
  @@adapter = :net_http
  @@enable_logging = false
  @@config = Config.new

  def self.config(opts=nil)
    return @@config if opts.nil?
    @@config = Config.new opts
  end

  def self.authorize_url(client_id=nil, redirect_uri=@@config.redirect_uri, opts={})
    raise "client_id required to authorize url. Pass with Geoloqi.config" unless client_id
    url = "#{OAUTH_URL}?response_type=code&client_id=#{Rack::Utils.escape client_id}&redirect_uri=#{Rack::Utils.escape redirect_uri}"
    url += "&#{Rack::Utils.build_query opts}" unless opts.empty?
    url
  end
end
