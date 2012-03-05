require File.join File.dirname(__FILE__), '..', 'env.rb'

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
              to_return(:status => 404, :body => {:error => 'not_found'}.to_json)

      expect { rescuing {Geoloqi::Session.new(:access_token => 'access_token1234').get('badmethodcall')}.class == Geoloqi::ApiError }
    end
  end

  describe 'custom exceptions scheme' do
    before do
      @session = Geoloqi::Session.new :access_token => 'access_token1234', :config => {:throw_exceptions => true,
                                                                                       :use_dynamic_exceptions => true}
    end

    it 'should throw api error exception with custom name' do
      stub_request(:get, api_url('specialerror')).
              with(:headers => auth_headers).
              to_return(:status => 404, :body => {:error => 'not_found'}.to_json)

      expect { rescuing {@session.get('specialerror')}.class == Geoloqi::NotFoundError }
    end
    
    it 'should throw api error exception without custom name if empty' do
      stub_request(:get, api_url('specialerror')).
              with(:headers => auth_headers).
              to_return(:status => 404, :body => {:error => ''}.to_json)

      expect { rescuing {@session.get('specialerror')}.class == Geoloqi::ApiError }
    end
  end

  describe 'with access token and throw exceptions false' do
    before do
      @session = Geoloqi::Session.new :access_token => 'access_token1234', :config => {:throw_exceptions => false}
    end

    it 'should not throw api error exception' do
      stub_request(:get, api_url('badmethodcall')).
              with(:headers => auth_headers).
              to_return(:status => 404, :body => {:error => 'not_found'}.to_json)

      response = @session.get 'badmethodcall'
      expect {response[:error] == 'not_found'}
    end
  end

  describe 'with access token and hashie mash' do
    before do
      @session = Geoloqi::Session.new :access_token => 'access_token1234', :config => {:use_hashie_mash => true}
    end

    it 'should respond to method calls in addition to hash' do
      stub_request(:get, api_url('account/username')).
        with(:headers => {'Authorization'=>'OAuth access_token1234'}).
        to_return(:body => {:username => 'bulbasaurrulzok'}.to_json)

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

    it 'successfully makes a batch request' do
      stub_request(:post, api_url('batch/run')).
        with(:body => {
         :access_token => 'access_token1234',
         :batch => [
           {:relative_url => '/layer/create', :body => {:name => 'Test 1'}, :headers => {}},
           {:relative_url => '/layer/create', :body => {:name => 'Test 2'}, :headers => {}}
          ]
        }.to_json, 
        :headers => { 
          'Authorization' => 'OAuth access_token1234',
          'Content-Type'  => 'application/json'}).
        to_return(:status => 200, :body => {:result => [
          {:code => 201, 
           :headers => [{:name => "Date", :value => "Wed, 08 Feb 2012 02:16:11 GMT"}],
           :body => {:layer_id => "abc", :name => "Test 1"},
           :time_ms => 11.373
          },
          {:code => 201,
           :headers => [{:name => "Date", :value => "Wed, 08 Feb 2012 02:16:11 GMT"}],
           :body => { :layer_id => "def", :name => "Test 2" },
           :time_ms => 10.735
          }]}.to_json)

      response = @session.batch do
        post '/layer/create', :name => 'Test 1'
        post '/layer/create', :name => 'Test 2'
      end

      expect { response.first[:code] == 201 }
      expect { response.first[:body][:layer_id] == 'abc' }
      expect { response.last[:body][:layer_id] == 'def' }
    end

    it 'throws an exception on a hard request error' do
      stub_request(:get, api_url('crashing_method')).
        with(:headers => auth_headers).
        to_return(:status => 500, :body => 'Something broke hard!')

        expect { rescuing {Geoloqi::Session.new(:access_token => 'access_token1234').get('crashing_method')}.class == Geoloqi::Error }
        expect { 
          rescuing {Geoloqi::Session.new(:access_token => 'access_token1234').get('crashing_method')}.message == 
          "API returned invalid JSON. Status: 500 Body: Something broke hard!"
        }
    end

    it 'successfully makes call with array' do
      stub_request(:post, api_url('play_record_at_geoloqi_hq')).
        with(:headers => auth_headers, :body => [{:artist => 'Television'}].to_json).
        to_return(:body => {:result => 'ok'}.to_json)

      expect { @session.post('play_record_at_geoloqi_hq', [{:artist => 'Television'}])[:result] == 'ok' }
    end

    it 'successfully makes call to api' do
      stub_request(:get, api_url('layer/info/Gx')).
        with(:headers => auth_headers).
        to_return(:status => 200, :body => {:layer_id => 'Gx'}.to_json)

      %w{/layer/info/Gx layer/info/Gx}.each do |path|
        expect { @session.get(path)[:layer_id] == 'Gx' }
      end
    end

    describe 'location/history' do
      before do
        stub_request(:get, api_url('location/history?count=2')).
          with(:headers => auth_headers).
          to_return(:status => 200, :body => {:points => [1,2]}.to_json)
      end

      it 'makes a location/history call with get and hash params' do
        expect { @session.get('location/history', :count => 2)[:points].count == 2 }
      end

      it 'makes a location/history call with get and query string directly in path' do
        expect { @session.get('location/history?count=2')[:points].count == 2 }
      end

      it 'makes a location/history call with get and query string params' do
        expect { @session.get('location/history', 'count=2')[:points].count == 2 }
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

  describe 'with- client id, client secret, and access token via direct hash' do
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
      expect { authorize_url == "#{Geoloqi.oauth_url}?"+
                                "response_type=code&"+
                                "client_id=#{Rack::Utils.escape CLIENT_ID}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
    end

    it 'gets authorize url with scope' do
      authorize_url = @session.authorize_url 'http://blah.blah/test', :scope => 'party_hard'
      expect { authorize_url == "#{Geoloqi.oauth_url}?"+
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
              to_return(:status => 401, :body => {:error => 'invalid_token'}.to_json)

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

  # PUT GENERAL TESTS IN HERE

  describe 'with config' do
    before do
      @session = Geoloqi::Session.new :config => {:client_id => CLIENT_ID, :client_secret => CLIENT_SECRET}
    end

    it 'retreives application access token data' do
      stub_request(:post, api_url('oauth/token')).
        with(:body => {:client_id => CLIENT_ID,
                       :client_secret => CLIENT_SECRET,
                       :grant_type => 'client_credentials'}.to_json).
        to_return(:status => 200,
                  :body => {:display_name => 'My App',
                            :username => 'madeuphashdontuseforanything',
                            :user_id => 'userid',
                            :is_anonymous => 0,
                            :access_token => 'app_access_token',
                            :scope => nil,
                            :expires_at => nil}.to_json)

      resp = @session.establish :grant_type => 'client_credentials'

      expect { resp[:display_name] == 'My App' }
      expect { resp[:access_token] == 'app_access_token' }

      expect { @session.application_access_token == 'app_access_token' }

      # Test the cache.
      @session.send(:instance_variable_set, :'@application_access_token', 'works')
      expect { @session.application_access_token == 'works' }
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
                            
      stub_request(:get, api_url('account/username')).
        with(:headers => {'Authorization'=>'OAuth access_token1234'}).
        to_return(:body => {:username => 'bulbasaurrulzok'}.to_json)

      response = @session.get_auth '1234', 'http://neverexpires.example.com/'

      expect { @session.auth[:expires_in] == '0' }
      expect { @session.auth[:expires_at].nil? }

      response = @session.get 'account/username'

      expect { @session.auth[:access_token] == 'access_token1234' }
      expect { response[:username] == 'bulbasaurrulzok' }
    end
    
    it 'does not attempt to refresh for auth code expire' do
      stub_request(:post, api_url('oauth/token')).
        with(:body => {:client_id => CLIENT_ID,
                       :client_secret => CLIENT_SECRET,
                       :grant_type => "authorization_code",
                       :code => "1234",
                       :redirect_uri => "http://expired_code.example.com/"}.to_json).
        to_return(:body => {:access_token => 'access_token1234',
                            :scope => nil,
                            :expires_in => '0',
                            :refresh_token => 'never_expires'}.to_json)
      
      stub_request(:get, api_url('account/username?code=1234')).
        with(:headers => auth_headers).
        to_return(:status => 200, :body => {:points => [1,2]}.to_json)
      
      # FINISH IMPLEMENTING
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
        to_return(:body => {:username => 'pikachu4lyfe'}.to_json)

      @session.get 'account/username'
      expect { @session.auth[:access_token] == 'access_token4567' }
    end
  end
end
