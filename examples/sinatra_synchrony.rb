# A simple Sinatra example demonstrating OAuth2 implementation with Geoloqi

# This version of the example uses sinatra-synchrony to implement an EventMachine-based app.
# Run this example with Thin (which uses EventMachine under the hood): ruby sinatra_synchrony.rb -s thin
# Works on anything that supports Thin (Rack, EY, Heroku, etc..)
# To install deps: gem install sinatra sinatra-synchrony geoloqi
#
# More information: http://kyledrake.net/sinatra-synchrony

require 'sinatra'
require 'sinatra/geoloqi'
require 'sinatra/synchrony'

# Get your client_id, client_secret, and set the redirect_uri on the Applications page at the Geoloqi Developer Site:
# https://developers.geoloqi.com

set :geoloqi_client_id,     'YOUR_APP_ID_GOES_HERE'
set :geoloqi_client_secret, 'YOUR_APP_SECRET_GOES_HERE'
set :geoloqi_redirect_uri,  'http://127.0.0.1:4567'
set :session_secret,        'ENTER_RANDOM_TEXT_HERE'

configure do
  Geoloqi.config :adapter => :em_synchrony
end

before do
  require_geoloqi_login
end

get '/?' do
  username = geoloqi.get('account/username')[:username]
  "You have successfully logged in as #{username}!"
end