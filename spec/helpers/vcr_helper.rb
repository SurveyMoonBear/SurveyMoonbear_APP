# frozen_string_literal: true

require 'vcr'
require 'webmock'
require 'json'

# Setting up VCR
class VcrHelper
  CASSETTES_FOLDER = 'spec/fixtures/cassettes'.freeze
  GS_CASSETTE = 'google_spreadsheet_api'.freeze

  def self.setup_vcr
    VCR.configure do |c|
      c.cassette_library_dir = CASSETTES_FOLDER
      c.hook_into :webmock
    end
  end

  def self.configure_vcr_for_gs
    VCR.configure do |c|
      c.filter_sensitive_data('<GOOGLE_CLIENT_ID>') { GOOGLE_CLIENT_ID }
      c.filter_sensitive_data('<GOOGLE_CLIENT_SECRET>') { GOOGLE_CLIENT_SECRET }
      c.filter_sensitive_data('<REFRESH_TOKEN>') { REFRESH_TOKEN }
      c.filter_sensitive_data('<SAMPLE_FILE_ID>') { SAMPLE_FILE_ID }
      c.filter_sensitive_data('<CURRENT_ACCOUNT>') { CURRENT_ACCOUNT }
      c.filter_sensitive_data('<ACCESS_TOKEN>') { ACCESS_TOKEN }

      # Filter some omitted credentials from http requests & responses
      # c.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
      #   interaction.request.headers['Authorization'][0] unless interaction.request.headers.empty? || interaction.request.headers['Authorization'].nil?
      #   JSON.parse(interaction.response.body)['access_token'] unless interaction.response.body.empty? || JSON.parse(interaction.response.body)['access_token'].nil?
      # end
    end

    VCR.insert_cassette(
      GS_CASSETTE,
      record: :new_episodes,
      match_requests_on: %i[method uri headers]
    )
  end

  def self.eject_vcr
    VCR.eject_cassette
  end
end