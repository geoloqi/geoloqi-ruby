# Bundler.setup
require 'rubygems'
require './lib/geoloqi.rb'
require 'minitest/autorun'
require 'webmock'

# Fix for RBX
require 'hashie/hash'

CLIENT_ID = 'client_id1234'
CLIENT_SECRET = 'client_secret1234'
ACCESS_TOKEN = 'access_token1234'

def auth_headers(access_token='access_token1234')
  {'Content-Type' => 'application/json',
   'User-Agent' => "geoloqi-ruby #{Geoloqi.version}",
   'Accept' => 'application/json',
   'Authorization' => "OAuth #{access_token}"}
end

def api_url(path); "#{Geoloqi.api_url}/#{Geoloqi.api_version}/#{path}" end

include WebMock::API