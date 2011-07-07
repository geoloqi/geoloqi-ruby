module Geoloqi
  class ApiError < StandardError
    attr_reader :type
    attr_reader :reason
    def initialize(type, reason=nil)
      @type = type
      @reason = reason
      message = type
      message += " - #{reason}" if reason
      super message
    end
  end

  class Error < StandardError; end
  class ArgumentError < ArgumentError; end
end