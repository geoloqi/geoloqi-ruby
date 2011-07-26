# A simple Sinatra example demonstrating OAuth2 implementation with Geoloqi
# This version of the example is powerful! It uses sinatra-synchrony to implement real concurrency with EventMachine. 
# Your calls to the Geoloqi api will not block the app from serving other requests!
# Run this example with Thin (which uses EventMachine under the hood): ruby sinatra_synchrony.rb -s thin
# Works on anything that supports Thin (Rack, EY, Heroku, etc..)

require 'rubygems'
require 'sinatra'
require 'sinatra/synchrony'
require 'geoloqi'

GEOLOQI_REDIRECT_URI = 'http://yourwebsite.net'

enable :sessions
set :session_secret, 'PUT A SECRET WORD HERE' # Encrypts the cookie session.. recommended.

def geoloqi
  @geoloqi ||= Geoloqi::Session.new :auth => session[:geoloqi_auth],
                                    :config => {:client_id => 'YOUR OAUTH CLIENT ID',
                                                :client_secret => 'YOUR CLIENT SECRET',
                                                :adapter => :em_synchrony}
end

# If the access token expires, Geoloqi::Session will refresh inline!
# This after block makes sure the session gets the updated config.
after do
  session[:geoloqi_auth] = @geoloqi.auth
end

get '/?' do
  geoloqi.get_auth(params[:code], GEOLOQI_REDIRECT_URI) if params[:code] && !geoloqi.access_token?
  redirect geoloqi.authorize_url(GEOLOQI_REDIRECT_URI) unless geoloqi.access_token?

  username = geoloqi.get('account/username')['username']
  "You have successfully logged in as #{username}!"
end

# To install deps: gem install sinatra sinatra-synchrony geoloqi
# To run from command line: ruby sinatra_synchrony.rb -s thin