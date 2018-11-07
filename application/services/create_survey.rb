# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  # Returns a new survey, or nil
  # Usage: CreateSurvey.new.call(config: <config>, current_account: {...}, title: "...")
  class CreateSurvey
    include Dry::Transaction
    include Dry::Monads

    step :exchange_access_token
    step :create_spreadsheet
    step :add_editor
    step :set_survey_title
    step :store_into_database

    def exchange_access_token(config:, current_account:, title:)
      response = HTTP.post('https://www.googleapis.com/oauth2/v4/token',
                           params: { refresh_token: config.REFRESH_TOKEN,
                                     client_id: config.GOOGLE_CLIENT_ID,
                                     client_secret: config.GOOGLE_CLIENT_SECRET,
                                     grant_type: 'refresh_token' }).parse
      current_account['access_token'] = response['access_token']
      Success(access_token: response['access_token'], 
              config: config, current_account: current_account, title: title)
    rescue
      Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
    end

    def create_spreadsheet(access_token:, config:, current_account:, title:)
      files_copy_url = "https://www.googleapis.com/drive/v3/files/#{config.SAMPLE_FILE_ID}/copy"
      response = HTTP.post("#{files_copy_url}?access_token=#{access_token}").parse

      Success(origin_id: response['id'], access_token: access_token, 
              current_account: current_account, title: title)
    rescue
      Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
    end

    def add_editor(origin_id:, access_token:, current_account:, title:)
      sleep(3)
      GoogleSpreadsheet.new(access_token)
                       .add_editor(origin_id, current_account['email'])
      Success(origin_id: origin_id, current_account: current_account, title: title)
    rescue
      Failure('Failed to add editor.')
    end

    def set_survey_title(origin_id:, current_account:, title:)
      spreadsheet_update_url = 'https://sheets.googleapis.com/v4/spreadsheets/'
      HTTP.auth("Bearer #{current_account['access_token']}")
          .post("#{spreadsheet_update_url}#{origin_id}:batchUpdate",
                json: { requests: [{
                  updateSpreadsheetProperties: {
                    properties: { title: title },
                    fields: 'title'
                  }
                }] })
      Success(origin_id: origin_id, current_account: current_account)
    rescue
      Failure('Failed to set survey title.')
    end

    def store_into_database(origin_id:, current_account:)
      google_api = Google::Api.new(current_account['access_token'])
      new_survey = Google::SurveyMapper.new(google_api)
                                       .load(origin_id, current_account)
      survey = Repository::For[new_survey.class].find_or_create(new_survey)
      Success(survey)
    rescue
      Failure('Failed to store the new survey into database.')
    end
  end
end
