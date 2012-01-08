module Geoloqi
  class Response
    # The HTTP status code of the response
    # @return [Fixnum]
    attr_reader :status
    
    # The HTTP Headers of the response
    # @return [Hash]
    attr_reader :headers
    
    # The body of the response
    # @return [String]
    attr_reader :body

    # Instantiate a response object.
    # @param status [Fixnum] The HTTP status code of the response
    # @param headers [Hash] The HTTP Headers of the response
    # @param body [String] The body of the response 
    # @example
    #  Geoloqi::Response.new 200, {'Server' => 'geoloqi-platform'}, '{"response":"ok"}'
    def initialize(status, headers, body)
      @status = status
      @headers = headers
      @body = body
    end
  end
end