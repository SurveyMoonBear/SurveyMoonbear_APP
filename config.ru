# frozen_string_literal: true

require_relative './init.rb'

use Rack::Static, 
  :urls => ['/googlea1597013a70c6f23.html'], 
  :root => 'public'

$stdout.sync = true
run SurveyMoonbear::App.freeze.app
