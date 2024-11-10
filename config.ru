# frozen_string_literal: true

require_relative './init'
require 'rack/session/cookie'
require 'rack/attack'
require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-scheduler/web'

# Enable Rack::Attack
use Rack::Attack

# Rack::Session::Cookie provides simple cookie based session management.
# By default, the session is a Ruby Hash stored as base64 encoded marshalled data set to :key (default: rack.session).
Sidekiq::Web.use(Rack::Session::Cookie, secret: ENV['SESSION_SECRET'])

# Secure Sidekiq::Web dashboard with HTTP Basic Authentication using Rack::Auth::Basic.
Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
  [username, password] == [ENV['SIDEKIQ_USER'], ENV['SIDEKIQ_PASSWORD']]
end

use Rack::Static,
  :urls => ['/googlea1597013a70c6f23.html'],
  :root => 'public'

# Rack::URLMap takes a hash mapping urls or paths to apps, and dispatches accordingly.
run Rack::URLMap.new('/' => SurveyMoonbear::App.freeze.app, '/sidekiq' => Sidekiq::Web)
# run SurveyMoonbear::App.freeze.app
