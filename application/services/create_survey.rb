# frozen_string_literal: true

require 'http'

module SurveyMoonbear
  # Returns a new survey, or nil
  class CreateSurvey
    def initialize(current_account, config)
      @current_account = current_account
      @config = config
    end

    def call(title)
      access_token = exchange_access_token
      origin_id = create_spreadsheet(access_token)
      add_editor(origin_id, access_token)
      set_survey_title(origin_id, title)
      store_into_database(origin_id)
    end

    def exchange_access_token
      response = HTTP.post('https://www.googleapis.com/oauth2/v4/token',
                           params: { refresh_token: @config.REFRESH_TOKEN,
                                     client_id: @config.GOOGLE_CLIENT_ID,
                                     client_secret: @config.GOOGLE_CLIENT_SECRET,
                                     grant_type: 'refresh_token' })
                     .parse
      response['access_token']
    end

    def create_spreadsheet(access_token)
      files_copy_url = "https://www.googleapis.com/drive/v3/files/#{@config.SAMPLE_FILE_ID}/copy"
      response = HTTP.post("#{files_copy_url}?access_token=#{access_token}").parse

      response['id']
    end

    def add_editor(origin_id, access_token)
      sleep(3)
      GoogleSpreadsheet.new(access_token)
                       .add_editor(origin_id, @current_account['email'])
    end

    def set_survey_title(origin_id, title)
      spreadsheet_update_url = 'https://sheets.googleapis.com/v4/spreadsheets/'
      HTTP.auth("Bearer #{@current_account['access_token']}")
          .post("#{spreadsheet_update_url}#{origin_id}:batchUpdate",
                json: { requests: [{
                  updateSpreadsheetProperties: {
                    properties: { title: title },
                    fields: 'title'
                  }
                }] })
    end

    def store_into_database(origin_id)
      google_api = Google::Api.new(@current_account['access_token'])
      new_survey = Google::SurveyMapper.new(google_api)
                                       .load(origin_id, @current_account)
      Repository::For[new_survey.class].find_or_create(new_survey)
    end
  end
end
