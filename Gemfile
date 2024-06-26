# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

# Google client lib
gem 'google-api-client'

# Web app related
gem 'figaro'
gem 'puma'
gem 'rack-attack'
gem 'rack-flash3'
gem 'rake'
gem 'roda'
gem 'slim'

# Services
gem 'dry-transaction'

# Security related
gem 'dry-validation'
gem 'rack-ssl-enforcer'
gem 'rbnacl'
gem 'secure_headers'

# Caching
gem 'rack-cache'
gem 'redis-rack-cache'

# Communication
gem 'http'
gem 'pony'
gem 'redis'
gem 'redis-rack'

gem 'httparty'
gem 'zlib'

# Diagnostic
gem 'pry'
gem 'rack-test'

# Database related
gem 'hirb'
gem 'sequel'

# WORKERS
gem 'cronex'
gem 'nokogiri'
gem 'sidekiq'
gem 'sidekiq-scheduler'

# Data gems
gem 'dry-struct'
gem 'dry-types'

gem 'plotly'

# Notification
gem 'aws-sdk-sns'

group :test do
  gem 'database_cleaner'
  gem 'minitest'
  gem 'minitest-hooks'
  gem 'minitest-rg'

  gem 'simplecov'
  gem 'vcr'
  gem 'webmock'
end

group :development, :test do
  gem 'flog'
  gem 'reek'
  gem 'rerun'
  gem 'rubocop'
  gem 'sqlite3'
end

group :production do
  gem 'pg'
end
