require 'sinatra'
require 'tilt/erubis'
require 'base64'

require_relative "library"

configure do
  set :library, Library.new()
end

configure(:development) do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  require 'sinatra/reloader'
  also_reload 'library.rb'
end

before do
  session[:messages] ||= []
  @library = settings.library
  @files = @library.items()
  @page_title = 'webreader'
end

helpers do
end

get '/' do
  erb :home
end

get '/reader/:id' do |id|
  @id = id
  erb :reader
end

get '/library/new' do
  @page_title = 'Upload'
  erb :upload
end

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

get '/library/:id' do |id|
  begin
    puts "Serving file: #{id} for reader"

    # content_type 'application/epub+zip'
    @library.get(id)
  rescue StandardError => e
    puts "Error serving EPUB for reader: #{e.message}"
    halt 404, e.message
  end
end

not_found do
  redirect '/'
end

def valid_filetype(filename)
  File.extname(filename).downcase == ".epub"
end
