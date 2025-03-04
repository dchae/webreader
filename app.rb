require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative "lib/helpers"
require_relative "lib/library"
require_relative "lib/users"
require_relative "lib/exceptions"
require_relative "lib/ui_components"

class App < Sinatra::Base
  helpers Sinatra::ContentFor
  helpers ApplicationHelpers

  UNRESTRICTED_PATHS = %w(/ /users/signin /users/signup).freeze

  configure do
    enable :sessions
    set :session_secret, ENV['SESSION_SECRET'] || SecureRandom.hex(32)
    set :erb, escape_html: true
    set :library, LibraryDBController.new()
  end

  configure(:development) do
    require 'sinatra/reloader'
    register Sinatra::Reloader
    also_reload('lib/*.rb')
  end

  before do
    @library = settings.library
    @users = UsersDBController.new(logger)
    @page_title = 'webreader'

    redirect_unless_signed_in unless UNRESTRICTED_PATHS.include?(request.fullpath)
  end

  after do
    # Ensure db connection is closed after processing each request
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
        add_message "Unsupported filetype. Please upload an epub."
        erb :upload
      else
        file = params[:upload][:tempfile].read
        puts "Attempting to upload file: #{filename}"
        puts "File size: #{file.bytesize} bytes"

        @library.add(filename, file)
        puts "File successfully added to library"

        add_message "File #{filename} uploaded successfully"
        redirect '/'
      end
    rescue StandardError => e
      puts "Error during upload: #{e.message}"
      puts e.backtrace
      add_message "Error uploading file: #{e.message}"
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
    @username = session[:user][:username]
    user_id = @users.fetch_user_id(@username)

    entry = @users.fetch_entry(user_id, @id).first
    @favorite = (entry && entry['favorite'] == "t") || false
    erb :reader
  end

  put '/users/:username/bookshelf/:book_id' do |username, book_id|
    begin
      # validate that current user is username
      validate_current_user(username)
      validate_book_id(book_id)
      user_id = @users.fetch_user_id(username)

      # Create a bookshelf entry if one does not yet exist
      entry = @users.fetch_entry(user_id, book_id)

      id = if entry.first
             entry.first['id']
           else
             @users.add_entry_and_return_id(user_id, book_id)
           end

      request_payload = JSON.parse(request.body.read)
      last_read_page = request_payload['last_read_page']
      favorite = request_payload['favorite']

      # Update the entry with the new values
      @users.update_entry(id, last_read_page, favorite)
      updated_entry = @users.fetch_entry_by_id(id).first

      # Return a JSON response
      content_type :json
      updated_entry.to_json
    rescue StandardError => e
      puts "Error in PUT route: #{e.message}"
      puts e.backtrace
      status 500
      content_type :json
      { error: e.message }.to_json
    end
  end

  not_found do
    # TODO: create 404 page
    redirect '/'
  end
end
