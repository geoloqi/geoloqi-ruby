require File.join File.dirname(__FILE__), '..', 'env.rb'

describe Geoloqi::ApiError do
  it 'throws exception properly and allows drill-down of message' do
    error = Geoloqi::ApiError.new 405, 'not_enough_cats', 'not enough cats to complete this request'
    error.status.must_equal 405
    error.type.must_equal 'not_enough_cats'
    error.reason.must_equal 'not enough cats to complete this request'
    error.message.must_equal "#{error.type} - #{error.reason} (405)"
  end
end