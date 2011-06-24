module Geoloqi
  class ApiError < StandardError
    def initialize(type, message=nil)
      type += " - #{message}" if message
      super type
    end
  end

  class Error < StandardError; end
end
