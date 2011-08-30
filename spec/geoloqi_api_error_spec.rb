require File.join File.dirname(__FILE__), 'env.rb'

describe Geoloqi::ApiError do
  it 'throws exception properly and allows drill-down of message' do
    error = Geoloqi::ApiError.new 405, 'not_enough_cats', 'not enough cats to complete this request'
    expect { error.status == 405 }
    expect { error.type == 'not_enough_cats' }
    expect { error.reason == 'not enough cats to complete this request' }
    expect { error.message == "#{error.type} - #{error.reason} (405)" }
  end
end