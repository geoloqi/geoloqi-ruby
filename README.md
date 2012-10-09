# Geoloqi Library for Ruby [![](https://secure.travis-ci.org/geoloqi/geoloqi-ruby.png)](http://travis-ci.org/geoloqi/geoloqi-ruby)
Powerful, flexible, lightweight interface to the Geoloqi Platform API.

This library was developed with two goals in mind: to be as simple as possible, but also to be very powerful to allow for much higher-end development (multiple Geoloqi apps per instance, concurrency, performance, thread-safety).

##Installation

    gem install geoloqi

##Basic Usage
Retrieve the client ID, client secret and application access token from your [Geoloqi Applications page](https://developers.geoloqi.com/applications) on the [Geoloqi Developers Site](https://developers.geoloqi.com).

Then you can use Geoloqi::Session to do things like create triggers:

    require "geoloqi"
    
    geoloqi_session = Geoloqi::Session.new({
      :access_token => "YOUR APPLICATION ACCESS TOKEN",
      :config       => {
        :client_id     => "YOUR CLIENT ID",
        :client_secret => "YOUR CLIENT SECRET",
      }
    })
    
    result = geoloqi_session.post("trigger/create", {
      :key        =>  "powells_books",
      :type       =>  "message",
      :latitude   =>  45.523334,
      :longitude  =>  -122.681612,
      :radius     =>  150,
      :text       =>  "Welcome to Powell's Books!",
      :place_name => "Powell's Books"
    })

Which returns a hash with the following:

    {
      :trigger_id    => "2sSW",
      :place_id      => "2Urq",
      :key           => "powells_books",
      :type          => "message",
      :trigger_on    => "enter",
      :trigger_after => 0,
      :one_time      => 0,
      :text          => "Welcome to Powell's Books!",
      :extra         => {},
      :place         => {
        :place_id     => "2Urq",
        :name         => "Powell's Books",
        :latitude     => 45.523334,
        :longitude    => -122.681612,
        :radius       => 150,
        :display_name => "Powell's Books",
        :active       => 1,
        :extra        => {},
        :description  => ""
      }
    }

##Hashie::Mash support
Want to access in a more OOP/JSON style way? Use Hashie::Mash as the response object:

    require 'hashie'
    require 'geoloqi'
    geoloqi = Geoloqi::Session.new :access_token => 'YOUR ACCESS TOKEN GOES HERE', :config => {:use_hashie_mash => true}
    response = geoloqi.get 'layer/info/Gx'
    response.layer_id    # this works
    response['layer_id'] # this works too
    response[:layer_id]  # so does this

##Making requests on behalf of the application
Some actions (such as "user/create") require escalated privileges. To use these, call app\_get and app\_post:

    geoloqi.app_post 'user/create_anon'

## API Documentation
The API has been extensively documented on [our developers site](https://developers.geoloqi.com/api).

## RDoc/YARD Documentation
The code has been fully documented, and the latest version is always available at the [Rubydoc Site](http://rubydoc.info/gems/geoloqi).

## Running the Tests

    $ bundle install
    $ bundle exec rake

In addition to a full test suite, there is Travis integration for 1.8, 1.9, JRuby and Rubinius.

##Found a bug?
Let us know! Send a pull request or a patch. Questions? Ask! We're here to help. File issues, we'll respond to them!

##Authors
* Kyle Drake
* Aaron Parecki
