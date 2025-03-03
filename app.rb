require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative "lib/helpers"
require_relative "lib/library"
require_relative "lib/users"
require_relative "lib/objects"

configure do
  set :erb, escape_html: true
end

configure(:development) do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  require 'sinatra/reloader'
  also_reload('lib/*.rb')
end

UNRESTRICTED_PATHS = %w(/ /users/signin /users/signup).freeze

before do
  session[:messages] ||= []
  @library = LibraryDBController.new()
  @users = UsersDBController.new(logger)
  @page_title = 'webreader'

  redirect_unless_signed_in unless UNRESTRICTED_PATHS.include?(request.fullpath)
end

after do
  # Ensure db connection is closed after processing each request
  @library.close_db()
  @users.close_db()
end

# Landing route

get '/' do
  redirect '/library' if signed_in?
  erb :landing, layout: :layout
end

# User routes
## Render Sign Up Page
get '/users/signup' do
  redirect_if_signed_in
  erb :signup
end

## Sign Up
post '/users/signup' do
  username = params[:username].strip
  password = params[:password]

  reload_on_invalid_signup_params(username, password)

  user_id = @users.add_user_and_return_id(username, password)
  signin_redirect(username, user_id)
end

# Render Sign In Page
get '/users/signin' do
  redirect_if_signed_in
  erb :signin
end

# Signin
post '/users/signin' do
  username = params[:username].strip
  password = params[:password]

  reload_on_error(:signin) do
    user_id = validate_signin_and_return_id(username, password)
    signin_redirect(username, user_id)
  end
end

## Signout
post '/users/signout' do
  signout
  redirect '/'
end

# Library routes

# Render all books
get '/library' do
  @files = @library.items()
  erb :library
end

# Render upload page
get '/library/new' do
  @page_title = 'Upload'
  erb :upload
end

# Upload epub file to library database
post '/library/new' do
  begin
    filename = params[:upload][:filename]
    if !valid_filetype(filename)
      session[:messages] << "Unsupported filetype. Please upload an epub."
      erb :upload
    else
      file = params[:upload][:tempfile].read
      puts "Attempting to upload file: #{filename}"
      puts "File size: #{file.bytesize} bytes"

      @library.add(filename, file)
      puts "File successfully added to library"

      session[:messages] << "File #{filename} uploaded successfully"
      redirect '/'
    end
  rescue StandardError => e
    puts "Error during upload: #{e.message}"
    puts e.backtrace
    session[:messages] << "Error uploading file: #{e.message}"
    erb :upload
  end
end

# Serve epub file
get '/library/:id' do |id|
  begin
    puts "Serving file: #{id} for reader"

    content_type 'application/epub+zip'
    @library.get(id)
  rescue StandardError => e
    puts "Error serving EPUB for reader: #{e.message}"
    halt 404, e.message
  end
end

# Reader routes
get '/reader' do
  @id = params[:id]
  erb :reader
end

not_found do
  # TODO: create 404 page
  redirect '/'
end
