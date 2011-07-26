raise ArgumentError, 'usage: be ruby spec/geoloqi_spec.rb "client_id" "client_secret" "access_token"' unless ARGV.length == 3
# Bundler.setup
require 'rubygems'
require './lib/geoloqi.rb'
require 'minitest/autorun'
require 'wrong'
require 'wrong/adapters/minitest'
require 'webmock'

Wrong.config.alias_assert :expect

describe Geoloqi do
  it 'reads geoloqi config' do
    Geoloqi.config :client_id => 'client_id', :client_secret => 'client_secret'
    expect { Geoloqi.config.is_a?(Geoloqi::Config) }
    expect { Geoloqi.config.client_id == 'client_id' }
    expect { Geoloqi.config.client_secret == 'client_secret' }
  end

  it 'returns authorize url' do
    authorize_url = Geoloqi.authorize_url 'test', 'http://blah.blah/test'
    expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                              'response_type=code&'+
                              "client_id=#{Rack::Utils.escape 'test'}&"+
                              "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
  end
end

describe Geoloqi::Config do
  describe 'with redirect_uri' do
    it 'returns authorize url' do
      Geoloqi.config :client_id => ARGV[0], :client_secret => ARGV[1], :redirect_uri => 'http://blah.blah/test'
      authorize_url = Geoloqi.authorize_url 'test'
      expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                                'response_type=code&'+
                                "client_id=#{Rack::Utils.escape 'test'}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
    end
  end

  it 'throws exception if non-boolean value is fed to logging' do
    expect { rescuing { Geoloqi.config(:client_id => '', :client_secret => '', :enable_logging => :cats )}.class == ArgumentError }
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
  before do
    WebMock.allow_net_connect!
  end

  describe 'with nothing passed' do
    before do
      @session = Geoloqi::Session.new
    end

    it 'should not find access token' do
      expect { !@session.access_token? }
    end
  end

  describe 'with access token and no config' do
    before do
      @session = Geoloqi::Session.new :access_token => ARGV[2]
    end

    it 'successfully makes mock call with array' do
      expect { @session.post('play_record_at_geoloqi_hq', [{:artist => 'Television'}])['result'] == 'ok' }
    end

    it 'successfully makes call to api with forward slash' do
      expect { @session.get('/layer/info/Gx')['layer_id'] == 'Gx' }
    end

    it 'successfully makes call to api without forward slash' do
      expect { @session.get('layer/info/Gx')['layer_id'] == 'Gx' }
    end

    it 'creates a layer, reads its info, and then deletes the layer' do
      layer_id = @session.post('/layer/create', :name => 'Test Layer')['layer_id']
      layer_info = @session.get "/layer/info/#{layer_id}"
      layer_delete = @session.post "/layer/delete/#{layer_id}"

      expect { layer_id.is_a?(String) }
      expect { !layer_id.empty? }
      expect { layer_info['name'] == 'Test Layer' }
      expect { layer_delete['result'] == 'ok' }
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

  describe 'with oauth id, secret, and access token via Geoloqi::Config' do
    it 'should load config' do
      @session = Geoloqi::Session.new :access_token => ARGV[2], :config => Geoloqi::Config.new(:client_id => ARGV[0],
                                                                                               :client_secret => ARGV[1])
      expect { @session.config.client_id == ARGV[0] }
      expect { @session.config.client_secret == ARGV[1] }
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
        session = Geoloqi::Session.new :access_token => ARGV[2], :config => {:adapter => :em_synchrony}
        response = session.get 'layer/info/Gx'
        expect { response['layer_id'] == 'Gx' }
      end
    end
  end

  describe 'with client id, client secret, and access token via direct hash' do
    before do
      @session = Geoloqi::Session.new :access_token => ARGV[2], :config => {:client_id => ARGV[0], :client_secret => ARGV[1]}
    end

    it 'should return access token' do
      expect { @session.access_token == ARGV[2] }
    end

    it 'should recognize access token exists' do
      expect { @session.access_token? }
    end

    it 'gets authorize url' do
      authorize_url = @session.authorize_url('http://blah.blah/test')
      expect { authorize_url == "#{Geoloqi::OAUTH_URL}?"+
                                "response_type=code&"+
                                "client_id=#{Rack::Utils.escape ARGV[0]}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
    end
  end

  describe 'with bunk access token' do
    before do
      @session = Geoloqi::Session.new :access_token => 'hey brah whats up let me in its cool 8)'
    end

    it 'fails with an exception' do
      expect { rescuing { @session.get 'message/send' }.message == 'invalid_token' }
    end
  end

  describe 'with config' do
    before do
      @session = Geoloqi::Session.new :config => {:client_id => ARGV[0], :client_secret => ARGV[1]}
    end

    it 'retrieves auth with mock' do
      WebMock.disable_net_connect!
      begin
        response = @session.get_auth('1234', 'http://test.site')
      ensure
        WebMock.allow_net_connect!
      end

      {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '86400',
                            :refresh_token => 'refresh_token1234'}.each do |k,v|
        expect { response[k] == v }
      end

      expect { (5..10).include? (Time.rfc2822(response[:expires_at]) - (Time.now+86400)).abs }
    end

    it 'retrieves auth with mock and removes code' do
      WebMock.disable_net_connect!
      begin
        response = @session.get_auth('1234', 'http://test.site?code=1234')
      ensure
        WebMock.allow_net_connect!
      end

      {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '86400',
                            :refresh_token => 'refresh_token1234'}.each do |k,v|
        expect { response[k] == v }
      end
    end
    
    it 'retrieves auth with mock, removes code, keeps other query string pair' do
      WebMock.disable_net_connect!
      begin
        response = @session.get_auth('1234', 'http://test.site/?code=1234&test=ok')
      ensure
        WebMock.allow_net_connect!
      end

      {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '86400',
                            :refresh_token => 'refresh_token1234'}.each do |k,v|
        expect { response[k] == v }
      end
    end
    
    it 'retrieves auth with mock, retains code in request_uri' do
      WebMock.disable_net_connect!
      begin
        response = @session.get_auth('1234', 'http://test.site/?code=1234&test=ok', false)
      ensure
        WebMock.allow_net_connect!
      end

      {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '86400',
                            :refresh_token => 'refresh_token1234'}.each do |k,v|
        expect { response[k] == v }
      end
    end
    
  end

  describe 'with config and expired auth' do
    before do
      @session = Geoloqi::Session.new :config => {:client_id => ARGV[0], :client_secret => ARGV[1]},
                                      :auth => { :access_token => 'access_token1234',
                                                 :scope => nil,
                                                 :expires_in => '86400',
                                                 :expires_at => Time.at(0).rfc2822,
                                                 :refresh_token => 'refresh_token1234' }
    end

    it 'retrieves new access token and retries query if expired' do
      WebMock.disable_net_connect!
      begin
        @session.get('account/username')
      ensure
        WebMock.allow_net_connect!
      end
      expect { @session.auth[:access_token] == 'access_token4567' }
    end
  end
end

include WebMock::API

stub_request(:post, "https://api.geoloqi.com/1/oauth/token").
  with(:body => {:client_id => ARGV[0],
                 :client_secret => ARGV[1],
                 :code => "1234",
                 :grant_type => "authorization_code",
                 :redirect_uri => "http://test.site"}.to_json).
  to_return(:status => 200,
            :body => {:access_token => 'access_token1234',
                      :scope => nil,
                      :expires_in => '86400',
                      :refresh_token => 'refresh_token1234'}.to_json)

stub_request(:post, "https://api.geoloqi.com/1/oauth/token").
  with(:body => {:client_id => ARGV[0],
                 :client_secret => ARGV[1],
                 :grant_type => "refresh_token",
                 :refresh_token => "refresh_token1234"}.to_json).
  to_return(:status => 200,
            :body => {:access_token => 'access_token4567',
                      :scope => nil,
                      :expires_in => '5000',
                      :refresh_token => 'refresh_token4567'}.to_json)

stub_request(:post, "https://api.geoloqi.com/1/oauth/token").
  with(:body => {:client_id => ARGV[0],
                 :client_secret => ARGV[1],
                 :code => "1234",
                 :grant_type => "authorization_code",
                 :redirect_uri => "http://test.site/?test=ok"}.to_json).
  to_return(:status => 200,
            :body => {:access_token => 'access_token1234',
                      :scope => nil,
                      :expires_in => '86400',
                      :refresh_token => 'refresh_token1234'}.to_json)

stub_request(:post, "https://api.geoloqi.com/1/oauth/token").
  with(:body => {:client_id => ARGV[0],
                 :client_secret => ARGV[1],
                 :code => "1234",
                 :grant_type => "authorization_code",
                 :redirect_uri => "http://test.site/?code=1234&test=ok"}.to_json).
  to_return(:status => 200,
            :body => {:access_token => 'access_token1234',
                      :scope => nil,
                      :expires_in => '86400',
                      :refresh_token => 'refresh_token1234'}.to_json)

stub_request(:get, "https://api.geoloqi.com/1/account/username").
  with(:headers => {'Authorization'=>'OAuth access_token4567'}).
  to_return(:status => 200,
            :body => {'username' => 'pikachu4lyfe'}.to_json)

# This is not a real API call, we're using it to test that arrays are JSON encoded.
stub_request(:post, "https://api.geoloqi.com/1/play_record_at_geoloqi_hq").
  with(:body => [{:artist => 'Television'}].to_json).
  to_return(:status => 200,
            :body => {'result' => 'ok'}.to_json)
