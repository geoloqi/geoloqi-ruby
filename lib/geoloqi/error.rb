module Geoloqi
  # Used for Geoloqi API errors (errors originating from the API server itself).
  class ApiError < StandardError
    # Status code of error
    # @return [Fixnum]
    # @example
    #  404, 500
    attr_reader :status

    # Type of error
    # @return [String]
    # @example
    #  "not_found", "invalid_input"
    attr_reader :type
    
    # Human-readable explanation of error.
    # @return [String]
    # @example
    #  "The requested resource could not found"
    attr_reader :reason

    # Instantiate a new ApiError object
    # @return [ApiError]
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

  # Used for config errors.
  class Error < StandardError; end
  
  # Used for argument errors.
  class ArgumentError < ArgumentError; end
end