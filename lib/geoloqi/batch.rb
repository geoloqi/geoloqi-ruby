module Geoloqi
  # This class is a builder/DSL class used to construct batch queries against the Geoloqi API. The best way to use this is
  # to use it from the Session class.
  # @see Session#batch
  class Batch
    # This keeps the batcher from going overboard.
    PER_REQUEST_LIMIT = 200 

    class NotImplementedError < StandardError; end

    def initialize(session, &block)
      @jobs = []
      @session = session
      self.instance_eval(&block)
    end

    def post(path, query=nil, headers={})
      @jobs << {
        :relative_url => path,
        :body => query,
        :headers => headers
      }
    end

    def get(path, query=nil, headers={})
      raise NotImplementedError, 'get requests are not yet implemented in batch'
    end

    def run!
      results = []

      until @jobs.empty?
        queued_jobs = @jobs.slice! 0, PER_REQUEST_LIMIT

        results << @session.post('batch/run', {
          :access_token => @session.access_token,
          :batch => queued_jobs
        })[:result]
      end

      results.flatten!
    end
  end
end