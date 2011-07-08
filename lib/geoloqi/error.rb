module Geoloqi
  class ApiError < StandardError
    attr_reader :status, :type, :reason
    def initialize(status, type, reason=nil)
      @status = status
      @type = type
      @reason = reason
      message = type
      message += " - #{reason}" if reason
      message += " (#{status})"
      super message
    end
  end

  class Error < StandardError; end
  class ArgumentError < ArgumentError; end
end
