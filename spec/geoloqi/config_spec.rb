require File.join File.dirname(__FILE__), '..', 'env.rb'

describe Geoloqi::Config do
  after do
    Geoloqi.config({})
  end
  
  describe 'with redirect_uri' do
    it 'returns authorize url' do
      Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :redirect_uri => 'http://blah.blah/test'
      authorize_url = Geoloqi.authorize_url 'test'
      authorize_url.must_equal "#{Geoloqi.oauth_url}?"+
                               'response_type=code&'+
                               "client_id=#{Rack::Utils.escape 'test'}&"+
                               "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}"
    end
  end
  
  it 'uses special api url' do
    stub_request(:get, 'https://apispecial.geoloqi.com/1/account/username').
      with(:headers => {'Authorization'=>'OAuth access_token1234'}).
      to_return(:body => {'username' => 'testuser'}.to_json)
    
    Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :api_url => 'https://apispecial.geoloqi.com'
    resp = Geoloqi.get ACCESS_TOKEN, 'account/username'
    resp[:username].must_equal 'testuser'
  end
  
  it 'displays log information if logger is provided' do
    stub_request(:get, api_url('account/username?cats=lol')).
      with(:headers => {'Authorization'=>'OAuth access_token1234'}).
      to_return(:body => {'username' => 'bulbasaurrulzok'}.to_json)
    
    io = StringIO.new
    Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :logger => io
    
    Geoloqi.get ACCESS_TOKEN, 'account/username', :cats => 'lol'
    io.string.must_match /Geoloqi::Session/
  end
  
  it 'displays log information if logger is provided and query is nil' do
    stub_request(:get, api_url('account/username')).
      with(:headers => {'Authorization'=>'OAuth access_token1234'}).
      to_return(:body => {:username => 'bulbasaurrulzok'}.to_json)
    
    io = StringIO.new
    Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :logger => io
    
    Geoloqi.get ACCESS_TOKEN, 'account/username'
    io.string.must_match /Geoloqi::Session/
  end

  it 'correctly checks booleans for client_id and client_secret' do
    [:client_id, :client_secret].each do |k|
      Geoloqi.config(k => '').send("#{k}?").must_equal false
      Geoloqi.config(k => nil).send("#{k}?").must_equal false
      Geoloqi.config(k => 'lol').send("#{k}?").must_equal true
    end
  end
end