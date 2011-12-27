require 'sinatra'
require 'sinatra/geoloqi'

# Get your client_id, client_secret, and set the redirect_uri on the Applications page at the Geoloqi Developer Site:
# https://developers.geoloqi.com

set :geoloqi_client_id,     'YOUR_APP_ID_GOES_HERE'
set :geoloqi_client_secret, 'YOUR_APP_SECRET_GOES_HERE'
set :geoloqi_redirect_uri,  'http://127.0.0.1:4567'
set :session_secret,        'ENTER_RANDOM_TEXT_HERE'

before do
  require_geoloqi_login
end

get '/?' do
  username = geoloqi.get('account/username')[:username]
  "You have successfully logged in as #{username}!"
end