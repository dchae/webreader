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

  def items
    @fs.find().each_with_object({}) do |file, hash|
      hash[file[:_id].to_s] = file[:filename]
    end
  end

  def files
    @fs.find.collect { |file| file[:filename] }
  end

  def add(filename, data)
    @fs.upload_from_stream(filename, StringIO.new(data))
  rescue StandardError => e
    puts "MongoDB error: #{e.message}"
    raise e
  end

  def get(id)
    stream = StringIO.new
    bson_id = BSON::ObjectId.from_string(id)
    @fs.download_to_stream(bson_id, stream)
    data = stream.string
    puts "Successfully retrieved #{data.bytesize} bytes"
    data
  rescue Mongo::Error::FileNotFound
    raise "File not found in MongoDB with id: #{id}"
  rescue StandardError => e
    puts "MongoDB error: #{e.message}"
    raise e
  end

  def get_by_filename(filename)
    stream = StringIO.new
    @fs.download_to_stream_by_name(filename, stream)
    data = stream.string
    puts "Successfully retrieved #{data.bytesize} bytes"
    data
  rescue Mongo::Error::FileNotFound
    raise "File not found in MongoDB with filename: #{filename}"
  rescue StandardError => e
    puts "MongoDB error: #{e.message}"
    raise e
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
end
