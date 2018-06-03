# frozen_string_literal: true

require 'http'

module SurveyMoonbear
  # Returns survey questions
  class GetSurveyQuestions
    def initialize(current_account)
      @current_account = current_account
    end

    def call(survey_id)
      detail = preadsheet_detail(survey_id)
      get_value_from_each_sheet(survey_id, detail)
    end

    def preadsheet_detail(survey_id)
      GoogleSpreadsheet.new(@current_account['access_token']).sheets(survey_id)
    end

    def get_value_from_each_sheet(survey_id, detail)
      sheets = detail[:sheets].map do |sheet|
        sheet_title = sheet['properties']['title']
        GoogleSpreadsheet.new(@current_account['access_token'])
                         .read(survey_id, sheet_title)
      end

      { title: detail[:title], sheets: sheets }
    end
  end
end
