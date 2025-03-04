module UIComponents
  class FlashMessage
    def initialize(content, type = :standard)
      @content = content
      @type = type
    end

    def css_class
      @type.to_s
    end

    def to_s
      @content
    end

    attr_reader :content, :type
  end

  class ErrorMessage < FlashMessage
    def initialize(content)
      super(content, :error)
    end
  end

  class SuccessMessage < FlashMessage
    def initialize(content)
      super(content, :success)
    end
  end
end
