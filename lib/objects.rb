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

# error classes

class ValidationError < StandardError
  def initialize(msg)
    @status_code = 400
    super(msg)
  end

  attr_reader :status_code
end

class InvalidFileSizeError < ValidationError
  def initialize(msg = 'File size must be less than 5MB.')
    super(msg)
  end
end

class InvalidSignupUsernameError < ValidationError
  def initialize(msg = 'Username length must be between 3 and 16 characters.')
    super(msg)
  end
end

class InvalidSignupPasswordError < ValidationError
  def initialize(msg = 'Password length must be between 8 and 32 characters.')
    super(msg)
  end
end

class UsernameTakenError < ValidationError
  def initialize(msg = 'A user with that username already exists.')
    super(msg)
  end
end

class InvalidSigninCredentialsError < ValidationError
  def initialize(msg = 'Invalid credentials.')
    super(msg)
  end
end

class NotSignedInError < ValidationError
  def initialize(msg = 'You must be signed in to perform this action.')
    super(msg)
  end
end

class UserPermissionsError < ValidationError
  def initialize(msg = 'You do not have permissions to perform this action.')
    super(msg)
  end
end

class NotFoundError < ValidationError
end

class UserNotFoundError < NotFoundError
  def initialize(msg = 'The requested user could not be found.')
    super(msg)
  end
end

class FileNotFoundError < NotFoundError
  def initialize(msg = 'The requested file could not be found.')
    super(msg)
  end
end

class PageNotFoundError < NotFoundError
  def initialize(msg = 'The requested page could not be found.')
    super(msg)
  end
end

class InvalidIdSyntaxError < NotFoundError
  def initialize(id, type = nil)
    super("`#{id}` is not a valid #{type}#{' ' if type}id.")
  end
end

class InvalidFileIdSyntaxError < InvalidIdSyntaxError
  def initialize(id)
    super(id, 'file')
  end
end
