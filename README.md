# Book Viewer

Simple browser-based reader application. Server is hosted with Sinatra and Puma. Books are stored in a MongoDB database. Users are stored in a PostgreSQL database.

## Dependencies

- `mongodb` (tested on v8.0.4)
- `postgreSQL` (tested on v14.17)
- `ruby` (tested on v3.2.2)

## Installation

- ensure you have dependencies installed
- clone the repo and enter the project directory
- run `bundle install`
- start server with `bundle exec puma`

## Roadmap

### Current

- [x] Users can sign-up and sign-in
- [x] ePubs can be uploaded
- [x] ePubs can be viewed
  - [x] Implement `epub.js` script
  - [x] Implement ePub reader controls
  - [x] Implement ePub chapter controls
- [x] move `epub.js` script to `./javascripts`
  - the script currently interpolates a ruby variable, change the reader route to take a query string instead of a path
- [ ] Debug "Too many open files" error
  - possible solution: `book.destroy()`?
- [x] Move helpers to a module
- [x] Encapsulate main app in a class
- [ ] Upload privileges (only certain users can upload) ??
- [x] Uploads are limited by file size (5MB)
- [ ] Basic CSS
- [ ] create admin panel, where I can:
  - [ ] Reset DBs
  - [ ] Delete books
  - [ ] Delete users
  - [ ] Manage user privileges

#### Visual

- [ ] Fix: reader is loading taller than expected, causing viewport overflow
- [ ] add fonts
- [ ] Grid view library

### Later

- [ ] User reading progress is saved
- [ ] Users can favorite books
- [ ] Implement collection pooling for databases
  - [x] mongoDB
  - [ ] psql
