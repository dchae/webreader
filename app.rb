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

get '/library/new' do
  @page_title = 'Upload'
  erb :upload
end

post '/library/new' do
  begin
    filename = params[:upload][:filename]
    if !is_epub(filename)
      session[:messages] << "Unsupported filetype. Please upload an epub."
      erb :upload
    else
      file = params[:upload][:tempfile].read
      puts "Attempting to upload file: #{filename}"
      puts "File size: #{file.bytesize} bytes"

      @library.add(filename, file)
      puts "File successfully added to MongoDB"

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
    # Get the original filename
    filename = @library.get_filename(id)
    puts "Serving EPUB: #{filename || id} for reader"
    # Set CORS headers to allow JavaScript to access this resource
    headers 'Access-Control-Allow-Origin' => '*'
    headers 'Access-Control-Allow-Methods' => 'GET, OPTIONS'
    headers 'Access-Control-Allow-Headers' => 'Content-Type, Accept, Range'
    headers 'Access-Control-Expose-Headers' => 'Content-Length, Content-Range'

    # Set content type but don't set Content-Disposition
    content_type 'application/epub+zip'

    # Set cache headers to improve performance
    cache_control :public, max_age: 3600

    @library.get(id)
  rescue StandardError => e
    puts "Error serving EPUB for reader: #{e.message}"
    halt 404, e.message
  end
end

get '/reader/:id' do |id|
  # Pass the ID to the template instead of constructing a URL
  @file_id = id
  erb :reader
end

# Handle OPTIONS requests for CORS preflight
options '/library/:id' do
  headers 'Access-Control-Allow-Origin' => '*'
  headers 'Access-Control-Allow-Methods' => 'GET, OPTIONS'
  headers 'Access-Control-Allow-Headers' => 'Content-Type, Accept, Range'
  headers 'Access-Control-Max-Age' => '86400' # 24 hours
  200
end

# Handle requests for EPUB entries
get '/library/:id/*' do |id, path|
  begin
    puts "Requested EPUB entry: #{path} from #{id}"

    # Get the content of the requested entry
    content = @library.get_epub_entry(id, path)

    # Set appropriate content type based on file extension
    ext = File.extname(path).downcase
    content_type case ext
                 when '.html', '.htm', '.xhtml' then 'text/html'
                 when '.css' then 'text/css'
                 when '.js' then 'application/javascript'
                 when '.jpg', '.jpeg' then 'image/jpeg'
                 when '.png' then 'image/png'
                 when '.gif' then 'image/gif'
                 when '.svg' then 'image/svg+xml'
                 when '.xml' then 'application/xml'
                 when '.opf' then 'application/oebps-package+xml'
                 when '.ncx' then 'application/x-dtbncx+xml'
                 else 'application/octet-stream'
                 end

    content
  rescue StandardError => e
    puts "Error serving EPUB entry: #{e.message}"
    halt 404, e.message
  end
end

# Handle OPTIONS requests for EPUB entries
options '/library/:id/*' do
  headers 'Access-Control-Allow-Origin' => '*'
  headers 'Access-Control-Allow-Methods' => 'GET, OPTIONS'
  headers 'Access-Control-Allow-Headers' => 'Content-Type, Accept, Range'
  200
end

not_found do
  redirect '/'
end

def is_epub(filename)
  # for validating files to be uploaded
  File.extname(filename).downcase == ".epub"
end
