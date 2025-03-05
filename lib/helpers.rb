# frozen_string_literal: true

require_relative "ui_components"
require_relative "exceptions"

# helpers
module ApplicationHelpers
  HOME_PATH = '/library'
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

  def validate_current_user(username)
    unless signed_in? && session[:user][:username] == username
      raise Exceptions::UserPermissionsError.new("You don't have permission to modify this user's information.")
    end
    true
  end

  def fetch_username(user_id)
    username = @users.fetch_username(user_id) if valid_id?(user_id)
    return username if username

    raise Exceptions::UserNotFoundError
  end

  # Render Helpers
  def add_message(content, type = :standard)
    return unless content
    session[:messages] ||= []
    options = { type: type }
    msg = UIComponents::FlashMessage.new(content, options)
    session[:messages] << msg
  end

  # Redirect helpers
  def redirect_if_signed_in
    return unless signed_in?

    add_message('You are already signed in.')
    redirect HOME_PATH
  end

  def redirect_unless_signed_in
    return if signed_in?

    add_message(Exceptions::NotSignedInError.new.message, :error)
    add_next_location(request.fullpath)
    redirect '/users/signin'
  end

  # Validation helpers
  def add_next_location(destination)
    session[:next_location] = destination
  end

  def reload_on_error(erb_sym)
    yield
  rescue Exceptions::ValidationError => e
    add_message(e.message, :error)
    halt e.status_code, erb(erb_sym)
  end

  def redirect_on_error(destination = HOME_PATH)
    yield
  rescue Exceptions::ValidationError => e
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

  alias valid_id? valid_numeric?

  def same_id?(id1, id2)
    id1.to_s == id2.to_s
  end

  # Validation methods
  ## Reload methods
  ### do not raise errors, just reload and display messages as flash
  def reload_on_invalid_signup_params(username, password)
    checks = [!@users.existing_user?(username), valid_username_length?(username),
              valid_password_length?(password)]
    errors = [Exceptions::UsernameTakenError.new, Exceptions::InvalidSignupUsernameError.new,
              Exceptions::InvalidSignupPasswordError.new]
    checks.zip(errors).each do |check, error|
      add_message(error.message, :error) unless check
    end
    halt 400, erb(:signup) unless checks.all?
  end

  ## Validate methods
  ### Raise Error if fails check
  def validate_signin_and_return_id(username, password)
    user_id = @users.validate_user_and_return_id(username, password)
    return user_id if user_id

    raise Exceptions::UserNotFoundError if user_id.nil?

    # if user_id == false
    raise Exceptions::InvalidSigninCredentialsError
  end

  def validate_book_id(id)
    unless @library.has(id)
      raise Exceptions::FileNotFoundError.new("Requested file with id: #{id} does not exist.")
    end
    true
  end
end
