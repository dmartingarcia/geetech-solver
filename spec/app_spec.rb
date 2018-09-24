require_relative 'spec_helper.rb'

RSpec.describe CaptchaSolverApp do
  it "should return a 400 BadRequest if you didn't send required params" do
    post '/captcha'
    expect(response_body).to eq({ "status" => "error", "message" => "Invalid parameters" })
    expect(last_response.status).to eq(400)
  end


  it "should return a 200 OK if you send required params" do
    allow_any_instance_of(Captcha).to receive(:obtain_solution).
                                        and_return({ x_pos: 10 })
    post '/captcha', params: { gt: 12345, challenge: 12345}

    expect(last_response.status).to eq(200)
    expect(response_body).to eq({ "status" => "ok", "x_pos" => 10 })
  end

  def response_body
    JSON.parse(last_response.body)
  end
end
