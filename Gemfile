source 'https://rubygems.org'
ruby '2.5.1'

# Google client lib
gem 'google-api-client'

# Web app related
gem 'econfig'
gem 'puma'
gem 'rack-flash3'
gem 'roda'
gem 'slim'
gem 'rake'

# Security related
gem 'dry-validation'
gem 'rack-ssl-enforcer'
gem 'rbnacl-libsodium'
gem 'secure_headers'

# Communication
gem 'http'
gem 'pony'
gem 'redis'
gem 'redis-rack'

# Diagnostic
gem 'tux'

# Database related
gem 'hirb'
gem 'sequel'

# Data gems
gem 'dry-struct'
gem 'dry-types'

group :test do
  gem 'minitest'
  gem 'minitest-rg'
  gem 'rack-test'
  gem 'simplecov'
  gem 'vcr'
  gem 'webmock'
end

group :development, :test do
  gem 'sqlite3'

  gem 'pry'
  gem 'rerun'
  
  gem 'flog'
  gem 'reek'
  gem 'rubocop'
end

group :production do
  gem 'pg'
end