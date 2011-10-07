module Geoloqi
  class Config
    attr_accessor :client_id, :client_secret, :redirect_uri, :adapter, :logger, :use_hashie_mash, :throw_exceptions, :use_dynamic_exceptions
    def initialize(opts={})
      self.use_hashie_mash ||= false
      self.throw_exceptions ||= true
      opts.each {|k,v| send("#{k}=", v)}
      begin
        require 'hashie' if self.use_hashie_mash && !defined?(Hashie::Mash)
      rescue LoadError
        raise Error, "You've requested Hashie::Mash, but the gem is not available. Don't set use_hashie_mash in your config, or install the hashie gem"
      end
    end

    def client_id?
      !client_id.nil? && !client_id.empty?
    end

    def client_secret?
      !client_secret.nil? && !client_secret.empty?
    end
  end
end