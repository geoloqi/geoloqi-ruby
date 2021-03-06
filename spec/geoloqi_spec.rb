require File.join File.dirname(__FILE__), 'env.rb'

describe Geoloqi do
  it 'reads geoloqi config' do
    Geoloqi.config :client_id => 'client_id', :client_secret => 'client_secret'
    Geoloqi.config.is_a?(Geoloqi::Config).must_equal true
    Geoloqi.config.client_id.must_equal 'client_id'
    Geoloqi.config.client_secret.must_equal 'client_secret'
  end

  describe 'authorize_url' do
    it 'is valid' do
      authorize_url = Geoloqi.authorize_url 'test', 'http://blah.blah/test'
      authorize_url.must_equal "#{Geoloqi.oauth_url}?"+
                               'response_type=code&'+
                               "client_id=#{Rack::Utils.escape 'test'}&"+
                               "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}"
    end

    it 'is valid with scope' do
      authorize_url = Geoloqi.authorize_url 'test', 'http://blah.blah/test', :scope => 'can_party_hard'
      authorize_url.must_equal "#{Geoloqi.oauth_url}?"+
                               'response_type=code&'+
                               "client_id=#{Rack::Utils.escape 'test'}&"+
                               "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}&"+
                               "scope=can_party_hard"
    end
  end

  it 'makes get request' do
    stub_request(:get, "https://api.geoloqi.com/1/quick_get?lol=cats").
      with(:headers => {'Authorization'=>'OAuth access_token1234', 'Special' => 'header'}).
      to_return(:body => {:result => 'ok'}.to_json)

    response = Geoloqi.get ACCESS_TOKEN, '/quick_get', {:lol => 'cats'}, 'Special' => 'header'
    response[:result].must_equal 'ok'
  end

  it 'makes post request' do
    stub_request(:post, "https://api.geoloqi.com/1/quick_post").
      with(:headers => {'Authorization'=>'OAuth access_token1234', 'Special' => 'header'},
           :body => {:lol => 'dogs'}.to_json).
      to_return(:body => {:result => 'ok'}.to_json)

    response = Geoloqi.post ACCESS_TOKEN, '/quick_post', {:lol => 'dogs'}, 'Special' => 'header'
    response[:result].must_equal 'ok'
  end
end