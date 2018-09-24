require_relative 'spec_helper.rb'

RSpec.describe Captcha do
  describe ".obtain_solution" do
    it "must execute the whole process" do
      VCR.use_cassette("geetest-integration") do
        codes = described_class.obtain_challenge_codes
        captchas = described_class.new(codes).request_geetest_info
        expect(captchas.keys.count).to eq(3)
        images = captchas.slice("bg", "full_bg").map do |captcha|
          described_class.obtain_captcha_image(captcha)
        end

        solution = described_class.puzzle_solution(images)
        expect(solution.keys).to eq([:x, :y, :diff])
      end
    end
  end

  describe "#obtain_challenge_codes" do
    it "return valid challenge codes" do
      VCR.use_cassette('geetech_challenge_codes') do
        codes = described_class.obtain_challenge_codes
        expect(codes.keys).to eq([:gt, :challenge])
        expect(codes[:gt]).to eq("f2ae6cadcf7886856696502e1d55e00c")
        expect(codes[:challenge]).to eq("626a9ef26c153d4d106a18b016c0e9bd")
      end
    end
  end

  describe "#obtain_captcha_image" do
    it "return processed file" do
      VCR.use_cassette("geetech_captcha_image") do
        url = "https://static.geetest.com/pictures/gt/597ec798a/597ec798a.webp"
        img1 = described_class.obtain_captcha_image(url)
        url = "https://static.geetest.com/pictures/gt/597ec798a/bg/d0bfdaec4.webp"
        img2 = described_class.obtain_captcha_image(url)

        solution = described_class.puzzle_solution(img1, img2)

        expect(solution[:x]).to eq(146)
        expect(solution[:y]).to eq(26)

        url = "https://static.geetest.com/pictures/gt/74cdf64c3/74cdf64c3.webp"
        img1 = described_class.obtain_captcha_image(url)
        url = "https://static.geetest.com/pictures/gt/74cdf64c3/bg/c9d421347.webp"
        img2 = described_class.obtain_captcha_image(url)

        solution = described_class.puzzle_solution(img1, img2)

        expect(solution[:x]).to eq(99)
        expect(solution[:y]).to eq(58)
      end
    end
  end

  describe ".request_geetest_info" do
    it "return valid captcha urls" do
      allow(Captcha).to receive(:get_callback_string).and_return("geetest_1537572366288")

      VCR.use_cassette('geetech_challenge_details') do
        expect(described_class.new({ challenge: "fa2ce30b8c37d188dbf5ba15240c0110",
                                     gt: "f2ae6cadcf7886856696502e1d55e00c" }).request_geetest_info.keys).to eq(["slice", "bg", "fullbg"])
      end
    end
  end
end
