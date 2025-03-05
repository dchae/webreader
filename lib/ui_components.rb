module UIComponents
  class FlashMessage
    def initialize(content, options = {})
      @content = content
      @type = options.fetch(:type, :standard)
      @dismissable = options.fetch(:dismissable, true)
      @timeout = options.fetch(:timeout, 3000)
    end

    def css_class
      @type.to_s
    end

    def to_s
      @content
    end

    attr_reader :content, :dismissable, :timeout
  end

  class ErrorMessage < FlashMessage
    def initialize(content)
      super(content, { type: :error })
    end
  end

  class SuccessMessage < FlashMessage
    def initialize(content)
      super(content, { type: :success })
    end
  end
end
