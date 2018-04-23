require 'http'

module SurveyMoonbear
  # Returns a new survey, or nil
  class CreateSurvey
    def initialize(current_account)
      @current_account = current_account
    end

    def call(title)
      create_spreadsheet(title)
    end

    def create_spreadsheet(title)
      response = GoogleSpreadsheet.new(@current_account[:access_token])
                                  .create(title: title)
      puts response

      { owner: @current_account,
        origin_id: response['spreadsheetId'],
        title: response['properties']['title'] }
    end
  end
end
