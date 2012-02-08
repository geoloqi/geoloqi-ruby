module Geoloqi
  class Batch
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
      @session.post 'batch/run', {
        :access_token => @session.access_token,
        :batch => @jobs
      }
    end
  end
end