# Create a layer, create a place on the layer, and then delete the place and the layer.

require 'rubygems'
require 'geoloqi'

geoloqi = Geoloqi::Session.new :oauth_token => 'YOUR OAUTH TOKEN GOES HERE'

layer_id = geoloqi.post('layer/create', :name => 'Test Layer')[:layer_id]

puts geoloqi.get("layer/info/#{layer_id}")

place_id = geoloqi.post('place/create', {
  :layer_id  => layer_id,
  :name      => "Munich on the Willamette",
  :latitude  => "45.5037078163837",
  :longitude => "-122.622699737549",
  :radius    => "3467.44",
  :extra     => {
    :description => "Portland",
    :url => "http://en.wikipedia.org/wiki/Portland,_Oregon"
  }
})[:place_id]

puts geoloqi.post("place/delete/#{place_id}")

puts geoloqi.post("layer/delete/#{layer_id}")