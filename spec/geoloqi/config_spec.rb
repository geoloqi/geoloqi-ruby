require File.join File.dirname(__FILE__), '..', 'env.rb'

describe Geoloqi::Config do
  describe 'with redirect_uri' do
    it 'returns authorize url' do
      Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :redirect_uri => 'http://blah.blah/test'
      authorize_url = Geoloqi.authorize_url 'test'
      expect { authorize_url == "#{Geoloqi.oauth_url}?"+
                                'response_type=code&'+
                                "client_id=#{Rack::Utils.escape 'test'}&"+
                                "redirect_uri=#{Rack::Utils.escape 'http://blah.blah/test'}" }
    end
  end
  
  it 'displays log information if logger is provided' do
    stub_request(:get, api_url('account/username?cats=lol')).
      with(:headers => {'Authorization'=>'OAuth access_token1234'}).
      to_return(:body => {'username' => 'bulbasaurrulzok'}.to_json)
    
    io = StringIO.new
    Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :logger => io
    
    Geoloqi.get ACCESS_TOKEN, 'account/username', :cats => 'lol'
    expect { io.string =~ /Geoloqi::Session/ }
  end
  
  it 'displays log information if logger is provided and query is nil' do
    stub_request(:get, api_url('account/username')).
      with(:headers => {'Authorization'=>'OAuth access_token1234'}).
      to_return(:body => {:username => 'bulbasaurrulzok'}.to_json)
    
    io = StringIO.new
    Geoloqi.config :client_id => CLIENT_ID, :client_secret => CLIENT_SECRET, :logger => io
    
    Geoloqi.get ACCESS_TOKEN, 'account/username'
    expect { io.string =~ /Geoloqi::Session/ }
  end

  it 'correctly checks booleans for client_id and client_secret' do
    [:client_id, :client_secret].each do |k|
      expect { Geoloqi.config(k => '').send("#{k}?") == false }
      expect { Geoloqi.config(k => nil).send("#{k}?") == false }
      expect { Geoloqi.config(k => 'lol').send("#{k}?") == true }
    end
  end
end