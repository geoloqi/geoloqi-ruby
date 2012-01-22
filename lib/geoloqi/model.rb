module Geoloqi

  module Model
    class Property
      attr_accessor :name, :type
      def initialize(name, type)
        @name = name
        @type = type
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def property(name, type)
        @_properties ||= []
        @_properties << Property.new(name, type)
        define_method "#{name}=" do |value|
          @_unsaved_attributes ||= []
          @_unsaved_attributes << name
          attribute_set name, value
        end
        attr_reader name
      end

      def properties
        @_properties
      end

      def property_keys
        properties.collect {|a| a.name}
      end

    end

    def save
      if @_new_record
        puts "CREATING RECORD"
        puts "TODO: Create record"
      end
      puts "SAVING #{attributes_get.inspect}"
      true
    end

    def attribute_set(name, value)
      raise ArgumentError, "property \"#{name}\" does not exist for this class" unless self.class.property_keys.include? name
      instance_variable_set "@#{name}".to_sym, value
    end

    def attribute_get(name)
      instance_variable_get name
    end

    def attributes_get
      attributes = {}
      self.class.property_keys.each {|key| attributes[key] = send(key)}
      attributes
    end

    def attributes(attributes=nil)
      return attributes_get if attributes.nil?
      send :attributes=, attributes
    end

    def attributes=(attributes={})
      attributes.each {|key, value| attribute_set key, value}
    end

    def unsaved_attributes
      @_unsaved_attributes ||= []
    end

    def unsaved_attributes?
      !unsaved_attributes.empty?
    end

    def initialize(attributes={})
      @_new_record = true
      attributes.each {|k,v| send("#{k}=", v) }
    end

    alias_method :to_hash, :attributes

    def to_json
      attributes.to_json
    end
  end
end