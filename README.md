# Book Viewer

A simple browser-based EPUB reader application built with Sinatra.

## Stack

- **Backend**: Ruby with Sinatra for routing and server-side logic
- **Storage**:
  - MongoDB for storing EPUB files
  - PostgreSQL for user accounts and reading preferences
- **Frontend**:
  - Vanilla JavaScript (no framework)
  - EPUB.js for rendering the EPUB content
  - Basic CSS for styling

## Features

- User authentication (signup/signin)
- EPUB file upload and storage
- Chapter navigation
- Favorite books management
- Responsive EPUB viewer

## Dependencies

- Ruby 3.3.4
- MongoDB 8.0.4+
- PostgreSQL 14.17+
- JavaScript libraries:
  - [epub.js](https://github.com/futurepress/epub.js)
  - [JSZip](https://stuk.github.io/jszip/)

## Installation

### Set session secret:

1. Generate secret (`openssl rand -hex 64`).
2. run `export SESSION_SECRET=generated_secret`

### Install and start:

1. Ensure MongoDB, and PostgreSQL are installed and running
2. Clone the repository
3. Run `bundle install` to install Ruby dependencies
4. Start the server with `bundle exec puma`

## Project Structure

- `app.rb`: Main application file with routes and configuration
- `lib/`: Helper modules and database controllers
- `views/`: ERB templates for the UI
- `public/`: Static assets (JavaScript, CSS)

## Roadmap

See [ROADMAP.md](ROADMAP.md)
