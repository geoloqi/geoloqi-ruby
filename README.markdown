Geoloqi Library for Ruby [![](https://secure.travis-ci.org/geoloqi/geoloqi-ruby.png)](http://travis-ci.org/geoloqi/geoloqi-ruby)
===
Powerful, flexible, lightweight interface to the awesome Geoloqi platform API! Uses Faraday, and can be used with Ruby 1.9 and EM-Synchrony for really fast, highly concurrent development.

This library was developed with two goals in mind: to be as simple as possible, but also to be very powerful to allow for much higher-end development (multiple Geoloqi apps per instance, concurrency, performance).

Installation
---

    gem install geoloqi

Basic Usage
---
Geoloqi uses OAuth2 for authentication, but if you're only working with your own account, you don't need to go through the authorization steps! Simply go to your account settings on the [Geoloqi site](http://geoloqi.com), click on "Connections" and copy the OAuth 2 Access Token. You can use this token to run the following examples.

If you just need to make simple requests, you can just make a simple get or post request from Geoloqi:

    require 'geoloqi'
    result = Geoloqi.get 'YOUR ACCESS TOKEN', 'layer/info/Gx'
    puts response.inspect

    # or a POST!
    result = Geoloqi.post 'YOUR ACCESS TOKEN', 'layer/create', :name => 'Test Layer'

If you're using Geoloqi with OAuth or making multiple requests, we recommend using the Geoloqi::Session class:

	require 'geoloqi'
	geoloqi = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN'
	response = geoloqi.get 'layer/info/Gx'
	puts response.inspect

Which returns a hash with the following:

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

Implementing OAuth2 is easy! We did all the hard work for you.

To demonstrate, there is a great, simple Geoloqi plugin for Sinatra! Here it is in action:

    require 'sinatra'
    require 'sinatra/geoloqi'

    set :geoloqi_client_id,     'YOUR_APP_ID_GOES_HERE'
    set :geoloqi_client_secret, 'YOUR_APP_SECRET_GOES_HERE'
    set :geoloqi_redirect_uri,  'http://127.0.0.1:4567'
    set :session_secret,        'ENTER_RANDOM_TEXT_HERE'

    before do
      require_geoloqi_login
    end

    get '/?' do
      username = geoloqi.get('account/username')['username']
      "You have successfully logged in as #{username}!"
    end

Click here to read more: [sinatra-geoloqi](https://github.com/geoloqi/sinatra-geoloqi)

There are also examples of how to implement Geoloqi's OAuth2 in the examples folder, for anyone working to embed with other frameworks (such as Ruby on Rails). Examples are also provided for integration with [sinatra-synchrony](http://github.com/kyledrake/sinatra-synchrony).

Found a bug?
---
Let us know! Send a pull request or a patch. Questions? Ask! We're here to help. File issues, we'll respond to them!

Authors
---
* Kyle Drake
* Aaron Parecki

TODO / Possible projects
---
* Rails plugin (works fine as-is, but maybe we can make it easier?)
* More Concrete API in addition to the simple one?
