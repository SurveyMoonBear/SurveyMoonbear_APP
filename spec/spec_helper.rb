# frozen_string_literal: false

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/hooks/default'
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
  'access_token' => ACCESS_TOKEN,
  'refresh_token' => REFRESH_TOKEN
}

STUDY_WITHOUT_NOTIFY_PARAMS = {
  'title' => 'test study without notify title',
  'desc' => 'test study without notify desc',
  'activity_start_at' => '',
  'activity_end_at' => ''
}
STUDY_WITH_NOTIFY_PARAMS = {
  'title' => 'test study with notify title',
  'desc' => 'test study with notify desc',
  'enable_notification' => 'true',
  'activity_start_at' => '',
  'activity_end_at' => ''
}

PARTICIPANT_WITHOUT_NOTIFY_PARAMS = {
  'nickname' => 'test participant without notify nickname',
  'contact_type' => 'email',
  'email' => 'moonbear.survey.test@gmail.com'.freeze,
  'phone' => '',
  'details' => '{"Name":"test_participant_without_notify_details"}',
  'aws_arn' => 'disable notification',
  'noti_status' => 'disabled'
}
PARTICIPANT_WITH_NOTIFY_PARAMS = {
  'nickname' => 'test participant with notify nickname',
  'contact_type' => 'email',
  'email' => 'moonbear.survey.test@gmail.com'.freeze,
  'phone' => '',
  'details' => '{"Name":"test_participant_with_notify_details"}',
  'aws_arn' => 'pending confirmation',
  'noti_status' => 'pending'
}

CALENDAR_ID = CONFIG.GOOGLE_ACCOUNT
CALENDAR_TEST_STUDY = {
  'title' => 'calendar test study',
  'desc' => 'calendar test study desc',
  'track_activity' => 'true',
  'activity_start_at' => '2022-05-01',
  'activity_end_at' => '2022-05-31'
}.freeze
CALENDAR_TEST_PARTICIPANT = {
  'nickname' => 'test',
  'contact_type' => 'email',
  'email' => CALENDAR_ID,
  'phone' => '',
  'details' => '',
  'aws_arn' => 'disable notification',
  'noti_status' => 'disabled'
}
