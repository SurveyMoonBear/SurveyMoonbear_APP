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
      c.ignore_localhost = true
    end
  end

  def self.configure_vcr_for_gs
    VCR.configure do |c|
      c.filter_sensitive_data('<GOOGLE_CLIENT_ID>') { GOOGLE_CLIENT_ID }
      c.filter_sensitive_data('<GOOGLE_CLIENT_SECRET>') { GOOGLE_CLIENT_SECRET }
      c.filter_sensitive_data('<REFRESH_TOKEN>') { REFRESH_TOKEN }
      c.filter_sensitive_data('<SAMPLE_FILE_ID>') { SAMPLE_FILE_ID }
      c.filter_sensitive_data('<VIZ_SAMPLE_FILE_ID>') { VIZ_SAMPLE_FILE_ID }
      c.filter_sensitive_data('<CALENDAR_ID>') { CALENDAR_ID }
      c.filter_sensitive_data('<CURRENT_ACCOUNT>') { CURRENT_ACCOUNT }
      c.filter_sensitive_data('<ACCESS_TOKEN>') { ACCESS_TOKEN }

      # Filter refresh_token from request uri
      c.filter_sensitive_data('<REFRESH_TOKEN>') do |interaction|
        uri = interaction.request.uri.to_s
        uri = uri.gsub('<SAMPLE_FILE_ID>/', '').gsub('<VIZ_SAMPLE_FILE_ID>/', '').gsub('<CALENDAR_ID>', '')
        uri_query_str = URI.parse(uri).query

        refresh_token_in_uri = URI.decode_www_form(uri_query_str).to_h['refresh_token'] unless uri_query_str.nil?
      end

      # Filter access_token from request uri
      c.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
        uri = interaction.request.uri.to_s
        uri = uri.gsub('<SAMPLE_FILE_ID>/', '').gsub('<VIZ_SAMPLE_FILE_ID>/', '').gsub('<CALENDAR_ID>', '')
        uri_query_str = URI.parse(uri).query

        access_token_in_uri = URI.decode_www_form(uri_query_str).to_h['access_token'] unless uri_query_str.nil?
      end

      # Filter access_token from request headers ('Authorization' => ["Bearer <ACCESS_TOKEN>"])
      c.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
        interaction.request.headers['Authorization'].first.split(' ')[1] if interaction.request.headers['Authorization']
      end

      # Filter access_token from response body string
      c.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
        body_str = interaction.response.body
        body_containing_access_token = !body_str.empty? && JSON.parse(body_str).keys.include?('access_token')
        JSON.parse(body_str)['access_token'] if body_containing_access_token
      rescue JSON::ParserError  # avoid invalid-json body_str causing error
      end

      c.filter_sensitive_data('<AWS_TOPIC_ARN>') do |interaction|
        body_str = interaction.response.body
        body_containing_aws_topic_arn = !body_str.empty? && body_str.include?('<TopicArn>')
        body_str.split('<TopicArn>')[1].split('</TopicArn>')[0] if body_containing_aws_topic_arn
      end

      c.filter_sensitive_data('<AWS_TOPIC_ARN>') do |interaction|
        body_str = interaction.request.body
        body_containing_aws_topic_arn = !body_str.empty? && body_str.include?('TopicArn')
        body_str.split('TopicArn=')[1].split('&Version')[0] if body_containing_aws_topic_arn
      end
    end
  end

  def self.build_cassette(cassette_name)
    VCR.insert_cassette(
      cassette_name.freeze,
      record: :new_episodes,
      match_requests_on: %i[method uri headers],
      allow_playback_repeats: true
    )
  end

  def self.eject_vcr
    VCR.eject_cassette
  end

  def self.block_vcr_alert
    VCR.configure do |c|
      c.allow_http_connections_when_no_cassette = true
    end
  end

  def self.unblock_vcr_alert
    VCR.configure do |c|
      c.allow_http_connections_when_no_cassette = false
    end
  end
end
