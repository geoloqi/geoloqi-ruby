require File.join '.', File.dirname(__FILE__), '..', 'env.rb'

class Widget
  include Geoloqi::Model
  property :name, :string
end

describe Widget do
  it 'adds property to class' do
    Widget.properties.first.name.must_equal :name
    Widget.properties.first.type.must_equal :string
  end

  it 'instantiates with property' do
    widget = Widget.new :name => 'Captain'
    widget.name.must_equal 'Captain'
    widget.to_hash.must_equal :name => 'Captain'
  end

  it 'instantiates with hash with nil name' do
    widget = Widget.new
    widget.to_hash.must_equal :name => nil
  end

  it 'adds attribute, registers updated attributes as dirty' do
    widget = Widget.new
    widget.unsaved_attributes.empty?.must_equal true
    widget.unsaved_attributes?.must_equal false

    widget.name = 'Captain'
    widget.name.must_equal 'Captain'
    widget.to_hash[:name].must_equal 'Captain'
  end

end