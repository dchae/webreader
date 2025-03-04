require 'pg'
require 'bcrypt'

# helpers
def file_path(filename = nil, subfolder = nil)
  test_dir = 'test/' if ENV['RACK_ENV'] == 'test'
  filename = File.basename(filename) if filename
  project_root = File.expand_path('../', __dir__)
  File.join(*[project_root, test_dir, subfolder, filename].compact)
end

# Class for querying database via PG gem
class UsersDBController
  DB_NAME = 'users'
  TEST_DB_NAME = "#{DB_NAME}_test"

  def initialize(logger = nil)
    @db_name = ENV['RACK_ENV'] == 'test' ? TEST_DB_NAME : DB_NAME
    @db = db_initializer
    @logger = logger
  end

  # Instance Methods
  ## Database init/close/reset methods (PG)
  def db_initializer
    # return a PG::Connection object
    PG.connect(dbname: @db_name)
  rescue PG::ConnectionBad
    # initialise db and return PG::Connection if db does not exist
    init_db
  end

  def init_db
    # When db does not exist, create the db
    # then add tables from /private/schema.sql
    default_db = PG.connect(dbname: 'postgres')
    safe_db_name = default_db.quote_ident(@db_name)
    default_db.exec("CREATE DATABASE #{safe_db_name}")
    default_db.close

    new_db = PG.connect(dbname: @db_name)
    sql = File.read(file_path('schema.sql', 'private'))
    new_db.exec(sql)

    # return a PG:Connection object
    new_db
  end

  def drop_db
    close_db

    begin
      default_db = PG.connect(dbname: 'postgres')
      safe_db_name = default_db.quote_ident(@db_name)
      default_db.exec("DROP DATABASE #{safe_db_name}")
    rescue PG::InvalidCatalogName
      log("Database #{@db_name} was not dropped because it does not exist.")
    ensure
      default_db.close
    end
  end

  def reset_db
    drop_db
    @db = init_db
  end

  def close_db
    @db.close
  rescue PG::ConnectionBad
    log('Database connection is already closed.')
  end

  ## User methods
  def add_user(username, secret)
    pw_hash = BCrypt::Password.create(secret).to_s
    sql = 'INSERT INTO users (username, pw_hash) VALUES ($1, $2)'
    query(sql, username, pw_hash)
  end

  def add_user_and_return_id(username, secret)
    pw_hash = BCrypt::Password.create(secret).to_s
    sql = <<~SQL
      INSERT INTO users (username, pw_hash)
      VALUES ($1, $2)
      RETURNING id;
    SQL
    result = query(sql, username, pw_hash)
    result.first['id']
  end

  def existing_user?(username)
    !!fetch_user_id(username)
  end

  def fetch_user_id(username)
    sql = 'SELECT id FROM users WHERE username = $1'
    result = query(sql, username)

    return false unless result.ntuples == 1

    result.first['id']
  end

  def fetch_username(user_id)
    sql = 'SELECT username FROM users WHERE id = $1'
    result = query(sql, user_id)

    return false unless result.ntuples == 1

    result.first['username']
  end

  def valid_user?(username, secret)
    sql = 'SELECT * FROM users WHERE username = $1'
    result = query(sql, username)

    pw_hash = result.first['pw_hash']
    log(BCrypt::Password.valid_hash?(pw_hash))
    BCrypt::Password.new(pw_hash) == secret
  end

  def validate_user_and_return_id(username, secret)
    # Returns nil if user does not exist
    # Returns user_id if credentials are correct
    # Returns false if credentials are incorrect
    sql = 'SELECT * FROM users WHERE username = $1'
    result = query(sql, username)
    return nil unless result.ntuples == 1

    pw_hash = result.first['pw_hash']
    log(BCrypt::Password.valid_hash?(pw_hash))
    BCrypt::Password.new(pw_hash) == secret && result.first['id']
  end

  def user_can_write?(user_id)
    sql = 'SELECT can_write FROM users WHERE id = $1'
    result = query(sql, user_id)

    return false unless result.ntuples == 1

    result.first['can_write']
  end

  ## bookshelf methods

  def add_entry_and_return_id(user_id, book_id)
    sql = <<~SQL
      INSERT INTO bookshelf (user_id, book_id)
      VALUES ($1, $2)
      RETURNING id;
    SQL
    result = query(sql, user_id, book_id)
    result.first['id']
  end

  def fetch_entry(user_id, book_id)
    sql = <<~SQL
      SELECT *
      FROM bookshelf
      WHERE user_id = $1
      AND book_id = $2;
    SQL
    query(sql, user_id, book_id)
  end

  def entry_exists?(user_id, book_id)
    !!fetch_entry(user_id, book_id)
  end

  def fetch_entry_by_id(entry_id)
    sql = <<~SQL
      SELECT bookshelf.*, username
      FROM bookshelf
      INNER JOIN users ON user_id = users.id
      WHERE bookshelf.id = $1;
    SQL
    query(sql, entry_id)
  end

  def fetch_n_entries(lim, page)
    sql = <<~SQL
      SELECT bookshelf.*, username
      FROM bookshelf
      INNER JOIN users ON bookshelf.user_id = users.id
      ORDER BY date_created DESC
      LIMIT $1 OFFSET $2;
    SQL
    offset = page.to_i * lim.to_i
    query(sql, lim.to_i + 1, offset)
  end

  def fetch_n_entries_by_user(lim, page, user_id)
    sql = <<~SQL
      SELECT bookshelf.*, username
      FROM bookshelf
      INNER JOIN users ON bookshelf.user_id = users.id
      WHERE user_id = $3
      ORDER BY date_created DESC
      LIMIT $1 OFFSET $2;
    SQL
    offset = page.to_i * lim.to_i
    query(sql, lim.to_i + 1, offset, user_id)
  end

  def update_entry(entry_id, last_read_page, favorite)
    sql = <<~SQL
      UPDATE bookshelf
      SET last_read_page = $1,
          favorite = $2,
          date_last_opened = NOW()
      WHERE id = $3;
    SQL
    query(sql, last_read_page, favorite, entry_id)
  end

  def delete_entry(entry_id)
    delete_row('bookshelf', entry_id)
  end

  ## Helper methods
  def log(msg)
    @logger&.info(msg)
  end

  def query(sql, *params)
    log("#{sql}: #{params}")
    @db.exec_params(sql, params)
  end

  def delete_row(table, id)
    safe_table_name = @db.quote_ident(table)
    sql = "DELETE FROM #{safe_table_name} WHERE id = $1"
    query(sql, id)
  end
end
