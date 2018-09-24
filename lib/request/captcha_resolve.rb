class Request
  class CaptchaResolve < Request::Base

    def initialize(request)
      super(request)
    end

    def process
      raise Error::InvalidParameters if parsed_parameters.keys.count != 2
      response = Captcha.new(parsed_parameters).obtain_solution
    end

    private

    def parsed_parameters
      @params ||= params.slice("challenge", "gt")
    end
  end
end
