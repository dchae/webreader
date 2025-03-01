require 'mongo'
require 'zip'
require 'tempfile'

class Library
  def initialize
    @db = Mongo::Client.new('mongodb://127.0.0.1:27017/library')
    @fs = Mongo::Grid::FSBucket.new(@db.database)
  end

  def close
    @db.close
  end

  def add(filename, data)
    @fs.upload_from_stream(filename, StringIO.new(data))
  rescue StandardError => e
    puts "MongoDB error: #{e.message}"
    raise e
  end

  def get(id)
    download_stream = StringIO.new
    object_id = BSON::ObjectId.from_string(id)

    # Get file info first to check if it exists
    file_info = @fs.find(_id: object_id).first

    if file_info.nil?
      raise "File not found with ID: #{id}"
    end

    puts "Retrieving file: #{file_info[:filename]} (#{file_info[:length]} bytes)"

    @fs.download_to_stream(object_id, download_stream)

    # Check if we got any data
    if download_stream.string.empty?
      raise "Downloaded empty file for ID: #{id}"
    end

    puts "Successfully retrieved #{download_stream.string.bytesize} bytes"

    download_stream.string
  rescue BSON::ObjectId::Invalid
    raise "Invalid ID format: #{id}"
  rescue Mongo::Error::FileNotFound
    raise "File not found in MongoDB with ID: #{id}"
  rescue StandardError => e
    puts "MongoDB error: #{e.message}"
    raise e
  ensure
    download_stream&.close
  end

  def items
    @fs.find({}).map { |file| [file[:_id].to_s, file[:filename]] }.to_h
  end

  def get_filename(id)
    object_id = BSON::ObjectId.from_string(id)
    file_info = @fs.find(_id: object_id).first
    file_info ? file_info[:filename] : nil
  rescue BSON::ObjectId::Invalid
    nil
  rescue StandardError => e
    puts "MongoDB error: #{e.message}"
    nil
  end

  # Extract a specific file from an EPUB
  def get_epub_entry(id, entry_path)
    # Get the full EPUB data
    epub_data = get(id)

    # Create a temporary file to work with
    temp_file = Tempfile.new(['epub', '.epub'])
    begin
      temp_file.binmode
      temp_file.write(epub_data)
      temp_file.flush

      # Open the EPUB as a ZIP file
      Zip::File.open(temp_file.path) do |zip_file|
        # Find the requested entry
        entry = zip_file.find_entry(entry_path)
        return entry.get_input_stream.read if entry
        # Return the content of the entry

        raise "Entry not found: #{entry_path}"
      end
    ensure
      temp_file.close
      temp_file.unlink
    end
  rescue StandardError => e
    puts "Error extracting EPUB entry: #{e.message}"
    raise e
  end

  # List all entries in an EPUB
  def list_epub_entries(id)
    # Get the full EPUB data
    epub_data = get(id)

    # Create a temporary file to work with
    temp_file = Tempfile.new(['epub', '.epub'])
    begin
      temp_file.binmode
      temp_file.write(epub_data)
      temp_file.flush

      entries = []
      # Open the EPUB as a ZIP file
      Zip::File.open(temp_file.path) do |zip_file|
        # List all entries
        zip_file.each do |entry|
          entries << entry.name
        end
      end
      entries
    ensure
      temp_file.close
      temp_file.unlink
    end
  rescue StandardError => e
    puts "Error listing EPUB entries: #{e.message}"
    raise e
  end
end
