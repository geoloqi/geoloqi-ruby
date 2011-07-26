# Bundler.setup
require 'rubygems'
require './lib/geoloqi.rb'
require 'minitest/autorun'
require 'wrong'
require 'wrong/adapters/minitest'
require 'em-http-request' if RUBY_VERSION[0..2].to_f >= 1.9 # Preload for WebMock
require 'webmock'
require 'webmock/http_lib_adapters/em_http_request'

CLIENT_ID = 'client_id1234'
CLIENT_SECRET = 'client_secret1234'
ACCESS_TOKEN = 'access_token1234'

def auth_headers(access_token='access_token1234')
  {'Content-Type' => 'application/json',
   'User-Agent' => "geoloqi-ruby #{Geoloqi.version}",
   'Accept' => 'application/json',
   'Authorization' => "OAuth #{access_token}"}
end

def api_url(path); "#{Geoloqi::API_URL}/#{Geoloqi::API_VERSION}/#{path}" end

Wrong.config.alias_assert :expect
include WebMock::API

describe Geoloqi do
  it 'reads geoloqi config' do
    Geoloqi.config :client_id => 'client_id', :client_secret => 'client_secret'
    expect { Geoloqi.config.is_a?(Geoloqi::Config) }
    expect { Geoloqi.config.client_id == 'client_id' }
    expect { Geoloqi.config.client_secret == 'client_secret' }
  end

  describe 'authorize_url' do
    it 'is valid' do
      authorize_url = Geoloqi.authorize_url 'test', 'http://blah.blah/test'
      expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                                'response_type=code&'+
                                "client_id=#{Rack::Utils.escape 'test'}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
    end

    it 'is valid with scope' do
      authorize_url = Geoloqi.authorize_url 'test', 'http://blah.blah/test', :scope => 'can_party_hard'
      expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                                'response_type=code&'+
                                "client_id=#{Rack::Utils.escape 'test'}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}&"+
                                "scope=can_party_hard" }
    end
  end
end

describe Geoloqi::ApiError do
  it 'throws exception properly and allows drill-down of message' do
    error = Geoloqi::ApiError.new 405, 'not_enough_cats', 'not enough cats to complete this request'
    expect { error.status == 405 }
    expect { error.type == 'not_enough_cats' }
    expect { error.reason == 'not enough cats to complete this request' }
    expect { error.message == "#{error.type} - #{error.reason} (405)" }
  end
end

describe Geoloqi::Config do
  describe 'with redirect_uri' do
    it 'returns authorize url' do
      Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :redirect_uri => 'http://blah.blah/test'
      authorize_url = Geoloqi.authorize_url 'test'
      expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                                'response_type=code&'+
                                "client_id=#{Rack::Utils.escape 'test'}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
    end
  end

  it 'throws exception if non-boolean value is fed to logging' do
    expect { rescuing { Geoloqi.config(:client_id => '', :client_secret => '', :enable_logging => :cats )}.class == Geoloqi::ArgumentError }
  end

  it 'correctly checks booleans for client_id and client_secret' do
    [:client_id, :client_secret].each do |k|
      expect { Geoloqi.config(k => '').send("#{k}?") == false }
      expect { Geoloqi.config(k => nil).send("#{k}?") == false }
      expect { Geoloqi.config(k => 'lol').send("#{k}?") == true }
    end
  end
end

describe Geoloqi::Session do
  describe 'with nothing passed' do
    before do
      @session = Geoloqi::Session.new
    end

    it 'should not find access token' do
      expect { !@session.access_token? }
    end
  end

  describe 'with access token and throw exceptions not set' do
    it 'should throw api error exception' do
      stub_request(:get, api_url('badmethodcall')).
              with(:headers => auth_headers).
              to_return(:status => 404, :body => {'error' => 'not_found'}.to_json)

      expect { rescuing {Geoloqi::Session.new(:access_token => 'access_token1234').get('badmethodcall')}.class == Geoloqi::ApiError }
    end
  end

  describe 'with access token and throw exceptions false' do
    before do
      @session = Geoloqi::Session.new :access_token => 'access_token1234', :config => {:throw_exceptions => false}
    end

    it 'should not throw api error exception' do
      stub_request(:get, api_url('badmethodcall')).
              with(:headers => auth_headers).
              to_return(:status => 404, :body => {'error' => 'not_found'}.to_json)

      response = @session.get 'badmethodcall'
      expect {response['error'] == 'not_found'}
    end
  end

  describe 'with access token and hashie mash' do
    before do
      @session = Geoloqi::Session.new :access_token => 'access_token1234', :config => {:use_hashie_mash => true}
    end

    it 'should respond to method calls in addition to hash' do
      stub_request(:get, api_url('account/username')).
        with(:headers => {'Authorization'=>'OAuth access_token1234'}).
        to_return(:body => {'username' => 'bulbasaurrulzok'}.to_json)

      response = @session.get 'account/username'
      expect { response['username'] == 'bulbasaurrulzok' }
      expect { response.username == 'bulbasaurrulzok' }
      expect { response[:username] == 'bulbasaurrulzok' }
    end
  end

  describe 'with access token and no config' do
    before do
      @session = Geoloqi::Session.new :access_token => ACCESS_TOKEN
    end

    it 'successfully makes mock call with array' do
      stub_request(:post, api_url('play_record_at_geoloqi_hq')).
        with(:headers => auth_headers, :body => [{:artist => 'Television'}].to_json).
        to_return(:body => {'result' => 'ok'}.to_json)

      expect { @session.post('play_record_at_geoloqi_hq', [{:artist => 'Television'}])['result'] == 'ok' }
    end

    it 'successfully makes call to api with forward slash' do
      stub_request(:get, api_url('layer/info/Gx')).
        with(:headers => auth_headers).
        to_return(:status => 200, :body => {'layer_id' => 'Gx'}.to_json)

      expect { @session.get('/layer/info/Gx')['layer_id'] == 'Gx' }
    end

    it 'successfully makes call to api without forward slash' do
      stub_request(:get, api_url('layer/info/Gx')).
        with(:headers => auth_headers).
        to_return(:status => 200, :body => {'layer_id' => 'Gx'}.to_json)

      expect { @session.get('layer/info/Gx')['layer_id'] == 'Gx' }
    end

    it 'creates a layer, reads its info, and then deletes the layer' do
      stub_request(:post, api_url('layer/create')).
        with(:headers => auth_headers, :body => {:name => 'Test Layer'}.to_json).
        to_return(:status => 200, :body => {:layer_id => 'layer_id1234'}.to_json)

      stub_request(:get, api_url('layer/info/layer_id1234')).
        with(:headers => auth_headers).
        to_return(:status => 200, :body => {:name => 'Test Layer'}.to_json)

      stub_request(:post, api_url('layer/delete/layer_id1234')).
        with(:headers => auth_headers).
        to_return(:status => 200, :body => {'result' => 'ok'}.to_json)

      layer_id = @session.post('/layer/create', :name => 'Test Layer')['layer_id']
      layer_info = @session.get "/layer/info/#{layer_id}"
      layer_delete = @session.post "/layer/delete/#{layer_id}"

      expect { layer_id.is_a?(String) }
      expect { !layer_id.empty? }
      expect { layer_info['name'] == 'Test Layer' }
      expect { layer_delete['result'] == 'ok' }
    end

    describe 'location/history' do
      before do
        stub_request(:get, api_url('location/history?count=2')).
          with(:headers => auth_headers).
          to_return(:status => 200, :body => {:points => [1,2]}.to_json)
      end

      it 'makes a location/history call with get and hash params' do
        expect { @session.get('location/history', :count => 2)['points'].count == 2 }
      end

      it 'makes a location/history call with get and query string directly in path' do
        expect { @session.get('location/history?count=2')['points'].count == 2 }
      end

      it 'makes a location/history call with get and query string params' do
        expect { @session.get('location/history', 'count=2')['points'].count == 2 }
      end
    end
  end

  describe 'with oauth id, secret, and access token via Geoloqi::Config' do
    it 'should load config' do
      @session = Geoloqi::Session.new :access_token => ACCESS_TOKEN,
                                      :config => Geoloqi::Config.new(:client_id => CLIENT_ID,
                                                                     :client_secret => CLIENT_SECRET)
      expect { @session.config.client_id == CLIENT_ID }
      expect { @session.config.client_secret == CLIENT_SECRET }
    end
  end

  # Ruby 1.9 only!
  if RUBY_VERSION[0..2].to_f >= 1.9
    begin
      require 'em-synchrony'
    rescue LoadError
      puts 'NOTE: You need the em-synchrony gem for all tests to pass: gem install em-synchrony'
    end
    describe 'with em synchrony adapter and access token' do
      it 'makes call to api' do
        session = Geoloqi::Session.new :access_token => ACCESS_TOKEN, :config => {:adapter => :em_synchrony}
        response = session.get 'layer/info/Gx'
        expect { response['layer_id'] == 'Gx' }
      end
    end
  end

  describe 'with client id, client secret, and access token via direct hash' do
    before do
      @session = Geoloqi::Session.new :access_token => ACCESS_TOKEN,
                                      :config => {:client_id => CLIENT_ID,
                                                  :client_secret => CLIENT_SECRET}
    end

    it 'should return access token' do
      expect { @session.access_token == ACCESS_TOKEN }
    end

    it 'should recognize access token exists' do
      expect { @session.access_token? }
    end

    it 'gets authorize url' do
      authorize_url = @session.authorize_url 'http://blah.blah/test'
      expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                                "response_type=code&"+
                                "client_id=#{Rack::Utils.escape CLIENT_ID}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
    end

    it 'gets authorize url with scope' do
      authorize_url = @session.authorize_url 'http://blah.blah/test', :scope => 'party_hard'
      expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                                "response_type=code&"+
                                "client_id=#{Rack::Utils.escape CLIENT_ID}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}&"+
                                "scope=party_hard" }
    end
  end

  describe 'with bunk access token' do
    before do
      @session = Geoloqi::Session.new :access_token => 'hey brah whats up let me in its cool 8)'
    end

    it 'fails with an exception' do
      stub_request(:post, api_url('message/send')).
              with(:headers => auth_headers('hey brah whats up let me in its cool 8)')).
              to_return(:status => 401, :body => {'error' => 'invalid_token'}.to_json)

      begin
        @session.post 'message/send'
      rescue Exception => e
        expect { e.class == Geoloqi::ApiError }
        expect { e.status == 401 }
        expect { e.type == 'invalid_token' }
        expect { e.message == 'invalid_token (401)' }
      end
    end
  end

  describe 'with config' do
    before do
      @session = Geoloqi::Session.new :config => {:client_id => CLIENT_ID, :client_secret => CLIENT_SECRET}
    end

    it 'retrieves auth with mock' do
      stub_request(:post, api_url('oauth/token')).
        with(:body => {:client_id => CLIENT_ID,
                       :client_secret => CLIENT_SECRET,
                       :grant_type => "authorization_code",
                       :code => "1234",
                       :redirect_uri => "http://example.com"}.to_json).
        to_return(:body => {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '86400',
                            :refresh_token => 'refresh_token1234'}.to_json)

      response = @session.get_auth '1234', 'http://example.com'

      {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '86400',
                            :refresh_token => 'refresh_token1234'}.each do |k,v|
        expect { response[k] == v }
      end

      expect { (5..10).include? (Time.rfc2822(response[:expires_at]) - (Time.now+86400)).abs }
    end

    it 'does not refresh when never expires' do
      stub_request(:post, api_url('oauth/token')).
        with(:body => {:client_id => CLIENT_ID,
                       :client_secret => CLIENT_SECRET,
                       :grant_type => "authorization_code",
                       :code => "1234",
                       :redirect_uri => "http://neverexpires.example.com/"}.to_json).
        to_return(:body => {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '0',
                            :refresh_token => 'never_expires'}.to_json)

      response = @session.get_auth '1234', 'http://neverexpires.example.com/'

      expect { @session.auth[:expires_in] == '0' }
      expect { @session.auth[:expires_at].nil? }

      response = @session.get 'account/username'

      expect { @session.auth[:access_token] == 'access_token1234' }
      expect { response['username'] == 'bulbasaurrulzok' }
    end
  end

  describe 'with config and expired auth' do
    before do
      @session = Geoloqi::Session.new :config => {:client_id => CLIENT_ID, :client_secret => CLIENT_SECRET},
                                      :auth => { :access_token => 'access_token1234',
                                                 :scope => nil,
                                                 :expires_in => '86400',
                                                 :expires_at => Time.at(0).rfc2822,
                                                 :refresh_token => 'refresh_token1234' }
    end

    it 'retrieves new access token and retries query if expired' do
      stub_request(:post, api_url('oauth/token')).
        with(:body => {:client_id => CLIENT_ID,
                       :client_secret => CLIENT_SECRET,
                       :grant_type => "refresh_token",
                       :refresh_token => "refresh_token1234"}.to_json).
        to_return(:body => {:access_token => 'access_token4567',
                            :scope => nil,
                            :expires_in => '5000',
                            :refresh_token => 'refresh_token4567'}.to_json)

      stub_request(:get, api_url('account/username')).
        with(:headers => {'Authorization'=>'OAuth access_token4567'}).
        to_return(:body => {'username' => 'pikachu4lyfe'}.to_json)

      @session.get 'account/username'
      expect { @session.auth[:access_token] == 'access_token4567' }
    end
  end
end
