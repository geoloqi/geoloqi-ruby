module Geoloqi
  class Config
    attr_accessor :client_id, :client_secret, :adapter, :enable_logging, :redirect_uri
    def initialize(opts={})
      opts.each {|k,v| send("#{k}=", v)}
      self.enable_logging ||= false
      raise ArgumentError, 'enable_logging must be boolean' unless [true, false].include? self.enable_logging
    end

    def client_id?
      !client_id.nil? && !client_id.empty?
    end

    def client_secret?
      !client_secret.nil? && !client_secret.empty?
    end
  end
end