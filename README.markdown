Geoloqi Library for Ruby
===
Powerful, flexible, lightweight interface to the awesome Geoloqi platform API! Uses Faraday, and can be used with Ruby 1.9 and EM-Synchrony for really fast, highly concurrent development.

This library was developed with two goals in mind: to be as simple as possible, but also to be very powerful to allow for much higher-end development (multiple Geoloqi apps per instance, concurrency, performance).

Installation
---

    gem install geoloqi

Basic Usage
---
Geoloqi uses OAuth2 for authentication, but if you're only working with your own account, you don't need to go through the authorization steps! Simply go to your account settings on the [Geoloqi site](http://geoloqi.com), click on "Connections" and copy the OAuth 2 Access Token. You can use this token to run the following examples:

	require 'geoloqi'
	geoloqi = Geoloqi::Session.new :access_token => 'YOUR OAUTH2 ACCESS TOKEN GOES HERE'
	response = geoloqi.get 'layer/info/Gx'
	puts response.inspect

This example returns a hash with the following:

	{"layer_id"=>"Gx", "user_id"=>"4", "type"=>"normal", "name"=>"USGS Earthquakes",
	 "description"=>"Real-time notifications of earthquakes near you.",
	 "icon"=>"http://beta.geoloqi.com/images/earthquake-layer.png", "public"=>"1",
	 "url"=>"https://a.geoloqi.com/layer/description/Gx", "subscription"=>false, "settings"=>false}

Both GET and POST are supported. To send a POST to create a place (in this case, the entire city of Portland, Oregon):

	response = geoloqi.post 'place/create', {
	  "layer_id" => "1Wn",
	  "name" => "3772756364",
	  "latitude" => "45.5037078163837",
	  "longitude" => "-122.622699737549",
	  "radius" => "3467.44",
	  "extra" => {
	    "description" => "Portland",
	     "url" => "http://en.wikipedia.org/wiki/Portland"
	  }
	}

This returns response['place_id'], which you can use to store and/or remove the place:

	response = geoloqi.post "place/delete/#{response['place_id']}"

Which returns response['result'] with a value of "ok".

You can send query string parameters with get requests too:

	geoloqi.get 'location/history', :count => 2
	# or
	geoloqi.get 'location/history?count=2'

Hashie::Mash support
---
Want to access in a more OOP/JSON style way? Use Hashie::Mash as the response object:

    require 'geoloqi'
    geoloqi = Geoloqi::Session.new :access_token => 'YOUR OAUTH2 ACCESS TOKEN GOES HERE', :config => {:use_hashie_mash => true}
    response = geoloqi.get 'layer/info/Gx'
    response.layer_id    # this works
    response['layer_id'] # this works too
    response[:layer_id]  # so does this

Implementing OAuth2
---

OAuth2 has been implemented so that it's very easy to store the session's authorization data in a hash. If the access token expires or becomes invalid, the refresh token is used to retrieve a fresh token. This is done automatically, so you don't have to worry about it. Just store the hash in a session, feed it back in on each request and you're good to go.

Here is a simple Sinatra example implementing the OAuth2 flow with Geoloqi:

	require 'rubygems'
	require 'sinatra'
	require 'geoloqi'

	GEOLOQI_REDIRECT_URI = 'http://yourwebsite.net'

	enable :sessions
	set :session_secret, 'PUT A SECRET WORD HERE' # Encrypts the cookie session.. recommended.

	def geoloqi
	  @geoloqi ||= Geoloqi::Session.new :auth => session[:geoloqi_auth],
	                                    :config => {:client_id => 'YOUR OAUTH CLIENT ID',
	                                                :client_secret => 'YOUR CLIENT SECRET'}
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

Now, here's a power example: Uses [sinatra-synchrony](http://github.com/kyledrake/sinatra-synchrony) to provide a massive concurrency improvement via EventMachine. This will allow your app to serve other requests, the app will not hang while waiting for content from the Geoloqi API. Works on anything that supports Thin (Rack, EY, Heroku, etc):

	# To install deps: gem install sinatra sinatra-synchrony geoloqi
	# To run from command line: ruby sinatra_synchrony.rb -s thin
	require 'rubygems'
	require 'sinatra'
	require 'sinatra/synchrony'
	require 'geoloqi'

	GEOLOQI_REDIRECT_URI = 'http://example.com'

	enable :sessions
	set :session_secret, 'PUT A SECRET WORD HERE'

	configure do
	  Geoloqi.config :client_id => 'YOUR OAUTH CLIENT ID', :client_secret => 'YOUR CLIENT SECRET', :adapter => :em_synchrony
	end

	def geoloqi
	  @geoloqi ||= Geoloqi::Session.new :auth => session[:geoloqi_auth]
	end
	
	after do
	  session[:geoloqi_auth] = @geoloqi.auth
	end

	get '/?' do
	  session[:geoloqi_auth] = geoloqi.get_auth(params[:code], GEOLOQI_REDIRECT_URI) if params[:code] && !geoloqi.access_token?
	  redirect geoloqi.authorize_url(GEOLOQI_REDIRECT_URI) unless geoloqi.access_token?
	  username = geoloqi.get('account/username')['username']
	  "You have successfully logged in as #{username}!"
	end

Found a bug?
---
Let us know! Send a pull request or a patch. Questions? Ask! We're here to help. File issues, we'll respond to them!

Authors
---
* Kyle Drake
* Aaron Parecki

TODO / Possible projects
---
* Plugin for Sinatra
* Rails plugin (works fine as-is, but maybe we can make it easier?)
* More Concrete API in addition to the simple one?