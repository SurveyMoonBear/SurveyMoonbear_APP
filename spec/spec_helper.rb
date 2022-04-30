# frozen_string_literal: false

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/hooks/default'
require 'database_cleaner'
require 'yaml'
require 'pry' # for debugging

require 'rack/test'
require './init.rb'
require_relative './helpers/init.rb'

include Rack::Test::Methods

def app
  SurveyMoonbear::App
end

CONFIG = app.config
GOOGLE_CLIENT_ID = CONFIG.GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET = CONFIG.GOOGLE_CLIENT_SECRET
REFRESH_TOKEN = CONFIG.REFRESH_TOKEN
SAMPLE_FILE_ID = CONFIG.SAMPLE_FILE_ID
VIZ_SAMPLE_FILE_ID = CONFIG.VIZ_SAMPLE_FILE_ID

ACCESS_TOKEN = SurveyMoonbear::Google::Auth.new(CONFIG).refresh_access_token
CURRENT_ACCOUNT = {
  'email' => 'moonbear.survey.test@gmail.com'.freeze,
  'username' => 'SurveyMoonbear Test'.freeze,
  'access_token' => ACCESS_TOKEN
}
