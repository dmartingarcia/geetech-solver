require 'sinatra'
Bundler.require(:default, ENV["RACK_ENV"])

require_all 'lib'

class CaptchaSolverApp < Sinatra::Base
  configure :development do
    disable :show_exceptions
  end

  post '/captcha' do
    content_type :json
    response = Request::CaptchaResolve.new(request).process
    response["status"] = "ok"

    response.to_json
  end

  error Error::InvalidParameters do
    status 400
    { status: :error, message: env['sinatra.error'].message }.to_json
  end
end
