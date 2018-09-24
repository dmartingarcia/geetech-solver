module Error
  class InvalidParameters < StandardError
    def initialize(msg = "Invalid parameters")
      super(msg)
    end
  end
end
