# frozen_string_literal: true

# run pry -r <path/to/this/file>
require './init.rb'
require 'rack/test'

include Rack::Test::Methods

def app
  SurveyMoonbear::App
end
