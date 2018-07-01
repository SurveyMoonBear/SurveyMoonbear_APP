# frozen_string_literal: true

module SurveyMoonbear
  # Return a survey entity from spreadsheet
  class GetSurveyFromSpreadsheet
    def initialize(current_account)
      @current_account = current_account
    end

    def call(spreadsheet_id)
      read_spreadsheet(spreadsheet_id)
    end

    def read_spreadsheet(spreadsheet_id)
      puts spreadsheet_id
      google_api = Google::Api.new(@current_account['access_token'])
      Google::SurveyMapper.new(google_api)
                          .load(spreadsheet_id, @current_account)
    end
  end
end
