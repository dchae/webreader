module UIComponents
  class FlashMessage
    def initialize(content, type = :standard)
      @content = content
      @type = type
    end

    def html_class
      @type.to_s
    end

    def to_s
      @content
    end

    attr_reader :content, :type
  end
end
