# frozen_string_literal: true

HOME_PATH = '/library'

# helpers
helpers do # rubocop:disable Metrics/BlockLength
  ## filesystem
  def file_path(filename = nil, subfolder = nil)
    test_dir = 'test/' if ENV['RACK_ENV'] == 'test'
    filename = File.basename(filename) if filename
    project_root = File.expand_path('../', __dir__)
    File.join(*[project_root, test_dir, subfolder, filename].compact)
  end

  def valid_filetype(filename)
    File.extname(filename).downcase == ".epub"
  end

  ## User helpers
  def setup_user_session(username, id)
    session[:user] = { username: username, id: id }
    add_message("Welcome #{username}!", :success)
  end

  def signin_redirect(username, user_id)
    setup_user_session(username, user_id)

    redirect_path = session[:next_location]
    session[:next_location] = nil
    redirect redirect_path || HOME_PATH
  end

  def signout
    add_message('You have been successfully signed out.', :success)
    session[:user] = nil
  end

  def signed_in?
    !!session[:user]
  end

  def fetch_username(user_id)
    username = @users.fetch_username(user_id) if valid_id?(user_id)
    return username if username

    raise UserNotFoundError
  end

  # Render Helpers
  def add_message(content, type = :standard)
    session[:messages] << FlashMessage.new(content, type) if content
  end

  # Redirect helpers
  def redirect_if_signed_in
    return unless signed_in?

    add_message('You are already signed in.')
    redirect HOME_PATH
  end

  def redirect_unless_signed_in
    return if signed_in?

    add_message(NotSignedInError.new.message, :error)
    add_next_location(request.fullpath)
    redirect '/users/signin'
  end

  # Validation helpers
  def add_next_location(destination)
    session[:next_location] = destination
  end

  def reload_on_error(erb_sym)
    yield
  rescue ValidationError => e
    add_message(e.message, :error)
    halt e.status_code, erb(erb_sym)
  end

  def redirect_on_error(destination = HOME_PATH)
    yield
  rescue ValidationError => e
    add_message(e.message, :error)
    redirect destination
  end

  def valid_username_length?(username)
    (3..16).include?(username.size)
  end

  def valid_password_length?(password)
    (8..32).include?(password.size)
  end

  def valid_numeric?(str)
    str =~ /^[0-9]+$/
  end

  alias_method :valid_id?, :valid_numeric?

  def same_id?(id1, id2)
    id1.to_s == id2.to_s
  end

  # Validation methods
  ## Reload methods
  ### do not raise errors, just reload and display messages as flash
  def reload_on_invalid_signup_params(username, password)
    checks = [!@users.existing_user?(username), valid_username_length?(username),
              valid_password_length?(password)]
    errors = [UsernameTakenError.new, InvalidSignupUsernameError.new,
              InvalidSignupPasswordError.new]
    checks.zip(errors).each do |check, error|
      add_message(error.message, :error) unless check
    end
    halt 400, erb(:signup) unless checks.all?
  end

  def reload_on_invalid_post_params(title, content, erb_sym)
    checks = [valid_post_title?(title), valid_post_content?(content)]
    errors = [InvalidPostTitleError.new, InvalidPostContentError.new]
    checks.zip(errors).each do |check, error|
      add_message(error.message, :error) unless check
    end
    halt 400, erb(erb_sym) unless checks.all?
  end

  ## Validate methods
  ### Raise Error if fails check
  def validate_signin_and_return_id(username, password)
    user_id = @users.validate_user_and_return_id(username, password)
    return user_id if user_id

    raise UserNotFoundError if user_id.nil?

    # if user_id == false
    raise InvalidSigninCredentialsError
  end

  def validate_post_owner(user_id, post_id)
    validation_check = @users.post_owner?(user_id, post_id)
    return if validation_check

    raise PostNotFoundError if validation_check.nil?

    raise PostPermissionsError
  end

  def validate_syntax_post_id(post_id)
    raise InvalidPostIdSyntaxError, post_id unless valid_id?(post_id)
  end

  def validate_comment_id(id, comments)
    raise InvalidCommentIdSyntaxError, id unless valid_id?(id)

    return if comments.map(&:id).include?(id)

    raise CommentNotFoundError
  end

  def validate_new_comment_params(content, post_id)
    return if valid_comment?(content)

    @post = fetch_post(post_id)
    @page_title = "#{@page_title}: #{@post.title}"
    load_comments(post_id)
    raise InvalidCommentParametersError
  end

  def validate_edit_comment_params(content)
    return if valid_comment?(content)

    raise InvalidCommentParametersError
  end

  def validate_comment_owner(user_id, comment_id, comments)
    comment_owner_id =
      comments.find { |comment| comment.id == comment_id }.user_id
    return if same_id?(user_id, comment_owner_id)

    raise CommentPermissionsError
  end
end
