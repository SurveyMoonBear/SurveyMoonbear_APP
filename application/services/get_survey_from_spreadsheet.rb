# frozen_string_literal: true

module SurveyMoonbear
  # Return a survey entity from spreadsheet
  class GetSurveyFromSpreadsheet
    def initialize(current_account)
      @current_account = current_account
    end

    def call(survey_id)
      read_spreadsheet(survey_id)
    end

    def read_spreadsheet(survey_id)
      google_api = Google::Api.new(@current_account['access_token'])
      Google::SurveyMapper.new(google_api)
                          .load(survey_id, @current_account)
    end
  end
end
