# Roadmap

## Current

- [ ] Debug "Too many open files" error
  - possible solution: `book.destroy()`?
- [ ] Basic CSS
- [ ] create admin panel, where I can:
  - [ ] Reset DBs
  - [ ] Delete books
  - [ ] Delete users
  - [ ] Manage user privileges

### Visual

- [ ] Fix: reader is loading taller than expected, causing viewport overflow
- [ ] add fonts
- [ ] Grid view library
- [ ] Flash messages rework
  - [ ] fixed position
  - [ ] auto-dismiss
  - [ ] dismiss on click

## Later

- [ ] User reading progress is saved
- [ ] reader font size can be changed
- [ ] reader font family can be changed
- [ ] Dark mode
- [ ] Implement collection pooling for databases
  - [x] mongoDB
  - [ ] psql

## Completed

- [x] Users can sign-up and sign-in
- [x] ePubs can be uploaded
- [x] ePubs can be viewed
  - [x] Implement `epub.js` script
  - [x] Implement ePub reader controls
  - [x] Implement ePub chapter controls
- [x] move `epub.js` script to `./javascripts`
  - the script currently interpolates a ruby variable, change the reader route to take a query string instead of a path
- [x] Move helpers to a module
- [x] Encapsulate main app in a class
- [x] Uploads are limited by file size (5MB)
- [x] Users can favorite books
