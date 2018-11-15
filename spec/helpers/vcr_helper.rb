# frozen_string_literal: true

require 'vcr'
require 'webmock'
require 'json'

# Setting up VCR
class VcrHelper
  CASSETTES_FOLDER = 'spec/fixtures/cassettes'.freeze
  
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
      
      # Filter access_token from request uri
      c.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
        uri_query_str = URI.parse( URI.encode(interaction.request.uri) )
                           .query

        access_token_in_uri = URI.decode_www_form(uri_query_str).to_h['access_token'] unless uri_query_str.nil?
      end

      # Filter access_token from response body string
      c.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
        body_str = interaction.response.body
        body_containing_access_token = !body_str.empty? && JSON.parse(body_str).keys.include?('access_token')

        JSON.parse(body_str)['access_token'] if body_containing_access_token
      end

      c.before_record do |interaction|
        interaction.request.headers.delete('Authorization')
      end
    end
  end

  def self.build_cassette(cassette_name)
    VCR.insert_cassette(
      cassette_name.freeze,
      record: :new_episodes,
      match_requests_on: %i[method uri headers]
    )
  end

  def self.eject_vcr
    VCR.eject_cassette
  end
end