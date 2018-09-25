require 'rmagick'
require 'chunky_png/rmagick'

class Captcha
  URL = "*r_captcha.html".freeze
  CHALLENGE_URL = "*r_captcha_challenge".freeze
  GEETEST_URL = "https://api-na.geetest.com/get.php?".freeze
  GEETEST_REFRESH_URL = "https://api-na.geetest.com/refresh.php?".freeze
  STATIC_FILE_URL = "https://static.geetest.com/".freeze
  COMPOSITION_HEIGHTS = 2
  COMPOSITION_WIDTHS = 26
  SCORE_THRESHOLD = 0.10

  attr_accessor :gt, :challenge

  def initialize(parameters)
    @gt = parameters[:gt]
    @challenge = parameters[:challenge]
  end

  def obtain_solution
    { xpos: 10 }
  end

  def calculate_w
    "hkUqrXXz3NpyF7inKZlkO4jHEcq2HGb5(p5RZRM2YnXkNbJ9kTOMJIpTGH9F38SAiP91nFqvLqB0DtXNkj1tl58Te(3M9eIVtwN6ANDUHP)x0vWUQRV7oFpBuIhjOZRHJBrXjrjF8POmegQP585hZXtQZuUA3mKdaOGoAvxLgBSpOj4(2CQAUodO5Pn6JDYgpdMt1mnBtAdVQqSjt5TT6ZAl6TARCvVagOb4XRKwzE4DdN7qBzUbVZi1KqGOqjGlNGAsFwD(2XHUmEwCqMJtCfx0B)dXn35Hkm(i9cn4efhBjViPSSU3pGrc1f7pYbdmAagmeE6l9Y)KzBxg(CGtAa(2Ddq2Lm4A(CecXxD2QvhbuQ(fIu(PUf1SiGGumAEZvBhtlu2hL8plqDTewK33jCDP6TetXoxH8Czt9tyP4jsDhUxQDpjgH71kxc7jtPCmQWtQfyYeCmqJQ9x0wI5RzY0ny7u6vLHiWzzF231HvtbfARb3BxOVXB(KzRzwpSbw0kntMYSe(UfPmnJq5OeChof4u6vsSWsXG98ISPYhRRz16JMzTtdCZXshgOaxMqua(c22dZYxtiUOhteitLQeWs5D983ci4d4kLNXCPONO0WftqdRxMsIpRcFdTeZDaPs8RNlw(6Qz9cSjsTyTVyR)uzBH)QnGALTYWC7CDwM5BkW4KY)ey0uXmebGa94xYN4jgmEbBrHxtybH(uVZpovcXyyHSO3He0vXRHvUNOFCRnG5(FTFnh)pMR(e7I0ip80WhHhb1YRGRTiA39nNgNFmwO7uZWvIWa1LdpgoUZqN(T1K3EvQb6WDkxGsp0hIzJMRpWnxC8TPrQCPGdM0z2BX6ytRF5(824XvdAOdO31zAcXPZK8lmEc8NWm77Mx9ZBvXiPnlRS2Ty5qWOyxmpUS7LZWnUjy6cH4O)g5M5UARPRb8G()0aeUwnYDlDS94FOTQduiIe5Tu9092ucAdH9k5FgEgOop4wrEmwMolENcVnZCkMTL3BIqjKwq(IUDDPu)9ee24e8c0037c86e807d2e151a8ed87495065f97bb7bd44ae11e7efea285bffd2a8677139d635288e0ca7cd0422f81866c41aad69e7ffb607f5a3c39cdc7b250745c902af437cb4886d2847d6c42294e31900fd753b93ff9d95df1f3f848711c8070fc5fcd52c5cad38d967928e1527ad1883ff5f0b01904cea8987bf317b877"
  end

  def request_geetest_info
    headers = {
      "Referer" => "https://www.infojobs.net/distil_r_captcha.html",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.75 Safari/537.36"
    }
    callback = self.class.get_callback_string
    params = {
      gt: @gt,
      challenge: @challenge,
      lang: "en",
      pt: 0,
      w: calculate_w,
      callback: callback
    }
    body = Typhoeus.get(GEETEST_URL, params: params, headers: headers).body
    byebug

    params = { is_next: true,
               type: "slide3",
               gt: @gt,
               challenge: @challenge,
               lang: "en",
               https: false,
               protocol: "https://",
               offline: false,
               product: "embed",
               api_server: "api-na.geetest.com",
               width: "100%",
               callback: callback }
    body = Typhoeus.get(GEETEST_URL, params: params, headers: headers).body
    byebug

    body = JSON.parse(body.split("(").last[0..-2])
    body = body.slice("slice", "bg", "fullbg")
    body.transform_values! { |v| STATIC_FILE_URL + v }
  end

  def self.obtain_challenge_codes
    body = Typhoeus.get(URL).body
    gt_code = body.match(/gt: '(.+)' ,/)[1]
    challenge_code = Typhoeus.post(CHALLENGE_URL).body.split(";").first

    { gt: gt_code,
      challenge: challenge_code }
  end

  def self.puzzle_solution(image_1, image_2)
    diff = []
    max_score = 0
    file_path = generate_temp_path("captcha-diff", "png")

    (0..(image_1.width-2)).each do |x|
      image_1.column(x).each_with_index do |pixel, y|
        score = Math.sqrt(
          (ChunkyPNG::Color.r(image_2[x,y]) - ChunkyPNG::Color.r(pixel)) ** 2 +
          (ChunkyPNG::Color.g(image_2[x,y]) - ChunkyPNG::Color.g(pixel)) ** 2 +
          (ChunkyPNG::Color.b(image_2[x,y]) - ChunkyPNG::Color.b(pixel)) ** 2
        ) / Math.sqrt(ChunkyPNG::Color::MAX ** 2 * 3)

        max_score = [score, max_score].max
        diff << [x, y] if score > SCORE_THRESHOLD
      end
    end

    diff.each do |x, y|
      image_2[x, y] = ChunkyPNG::Color.rgb(0,255,0)
    end

    image_2.save(file_path)

    { x: diff.map(&:first).first,  y: diff.map(&:last).first, diff: file_path.split("/").last }
  end

  def self.obtain_captcha_image(url)
    captcha_binary = Typhoeus.get(url).body
    webp_file = Tempfile.new(["captcha", ".webp"], "/tmp")
    webp_file.write(captcha_binary)
    webp_file.close
    path = webp_file.path
    new_path = path.split(".").first + ".png"
    `dwebp #{path} -o #{new_path}`
    webp_file.unlink

    image = ChunkyPNG::Canvas.from_file(new_path)
    height = image.dimension.height
    width = image.dimension.width
    height_increment = height / COMPOSITION_HEIGHTS
    width_increment = width / COMPOSITION_WIDTHS

    canvas_parts = []
    ypos = 0
    (0..COMPOSITION_HEIGHTS-1).each do |index_1|
      xpos = 0
      (0..COMPOSITION_WIDTHS-1).each do |index_2|
        canvas_parts << image.crop(xpos, ypos, (width_increment -1), height_increment)
        xpos += width_increment
      end
      ypos += height_increment
    end
    image = ChunkyPNG::Canvas.new(261, 160)

    transformation_order = [39, 38, 48, 49, 41, 40, 46, 47, 35, 34, 50, 51, 33, 32, 28, 29, 27, 26, 36, 37, 31, 30, 44, 45, 43, 42,
                            12, 13, 23, 22, 14, 15, 21, 20,  8,  9, 25, 24,  6,  7,  3,  2,  0,  1, 11, 10,  4,  5, 19, 18, 16, 17]

    ypos = 0
    (0..COMPOSITION_HEIGHTS-1).each do |index_1|
      xpos = 0
      (0..COMPOSITION_WIDTHS-1).each do |index_2|
        index = index_1 * COMPOSITION_WIDTHS + index_2
        canvas_index = transformation_order[index]
        image_part = canvas_parts[canvas_index]
        image = image.compose(image_part, xpos, ypos)
        xpos += (width_increment - 2)
      end
      ypos += height_increment
    end

    image.save(new_path, :fast_rgba)
    image
  end

  private

  def self.get_callback_string
    "geetest_" + DateTime.now.strftime('%Q')
  end

  def self.generate_temp_path(name, extension, folder = "/tmp")
    file = Tempfile.new([name, ".#{extension}"], folder)
    file_path = file.path
    file.close
    file.unlink

    file_path
  end
end
