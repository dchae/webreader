# Roadmap

## Current Focus

### Visual Improvements

- [ ] Grid view for library display

## Planned Features

### User Experience

- [ ] User reading progress persistence
- [ ] Customizable reader font size
- [ ] Customizable font family selection
- [ ] Dark mode support

### Administration

- [ ] Admin panel with capabilities to:
  - [ ] Reset databases
  - [ ] Delete books
  - [ ] Delete users
  - [ ] Manage user privileges

### Development

- [ ] Write unit tests
- [ ] Implement collection pooling for PostgreSQL database
- [ ] Optimize performance for large libraries

## Completed ✓

### Core Functionality

- [x] Users can sign-up and sign-in
- [x] EPUBs can be uploaded and stored
- [x] EPUBs can be viewed with full reader controls
- [x] Users can favorite books

### Architecture

- [x] Move helpers to a module
- [x] Encapsulate main app in a class
- [x] Move `epub.js` script to its own module in `./javascripts`

### UI Improvements

- [x] Basic CSS styling
- [x] Custom font integration
- [x] Flash messages improvements:
  - [x] Fixed position notifications
  - [x] Auto-dismiss functionality
  - [x] Click-to-dismiss option

### Bug Fixes

- [x] Fixed "Too many open files" error with persistent MongoDB connection
- [x] Fixed reader viewport overflow issue
- [x] Implemented file size limits for uploads (5MB)
