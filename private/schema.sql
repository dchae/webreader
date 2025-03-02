CREATE TABLE users (
  id serial PRIMARY KEY,
  username varchar(16) UNIQUE NOT NULL,
  pw_hash text NOT NULL,
  join_date timestamp DEFAULT NOW(),
  can_write boolean NOT NULL DEFAULT false
);

CREATE TABLE bookshelf (
  id serial PRIMARY KEY,
  user_id int NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  book_id text NOT NULL,
  date_last_opened timestamp DEFAULT NOW(),
  last_read_page int NOT NULL DEFAULT 0,
  favorite boolean NOT NULL DEFAULT true
);
