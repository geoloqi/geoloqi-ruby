module Geoloqi
  class Response
    attr_reader :status, :headers, :body
    def initialize(status, headers, body)
      @status = status
      @headers = headers
      @body = body
    end
  end
end