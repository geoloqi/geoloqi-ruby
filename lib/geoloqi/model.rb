module Geoloqi
  module Model

    class Property
      attr_accessor :name, :type
      def initialize(name, type)
        @name = name
        @type = type
      end
    end

    class Base
      @@properties = []

      class << self
        def property(name, type)
          @@properties << Property.new(name, type)
          define_method "#{name}=" do |value|
            @unsaved_attributes ||= []
            @unsaved_attributes << name
            attribute_set name, value
          end
          attr_reader name
        end

        def properties
          @@properties
        end

        def property_keys
          properties.collect {|a| a.name}
        end
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

      def initialize(attributes={})
        attributes.each {|k,v| send("#{k}=", v) }
      end

      alias_method :to_hash, :attributes

      def to_json
        attributes.to_json
      end
    end
  end
end