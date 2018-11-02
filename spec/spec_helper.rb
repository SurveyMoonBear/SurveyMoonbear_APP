ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/hooks/default'
require 'database_cleaner'
require 'yaml'
require 'pry' # for debugging

require_relative './helpers/init.rb'
require_relative './test_load_all.rb'

CONFIG = app.config
CURRENT_ACCOUNT = {
  'email' => 'moonbear.survey.test@gmail.com', 
  'username' => 'SurveyMoonbear Test',
  'access_token' => GoogleAuthHelper.exchange_access_token(CONFIG)
}
