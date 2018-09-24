class Request
  class Base
    attr_accessor :request
    attr_accessor :params

    def initialize(request)
      @request = request
      @params = request.params["params"] || {}
    end
  end
end
