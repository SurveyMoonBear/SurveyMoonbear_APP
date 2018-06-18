# frozen_string_literal: true

require 'http'

module SurveyMoonbear
  class EditSurveyTitle
    def initialize(current_account)
      @current_account = current_account
    end

    def call(survey_id, params)
      origin_id = get_survey_origin_id(survey_id)
      update_spreadsheet_title(origin_id, params['title'])
      update_survey_title(origin_id)
    end

    def get_survey_origin_id(survey_id)
      survey = Repository::For[Entity::Survey].find_id(survey_id)
      survey.origin_id
    end

    def update_spreadsheet_title(origin_id, new_title)
      spreadsheet_update_url = 'https://sheets.googleapis.com/v4/spreadsheets/'
      HTTP.auth("Bearer #{@current_account['access_token']}")
          .post("#{spreadsheet_update_url}#{origin_id}:batchUpdate",
                json: { requests: [{
                  updateSpreadsheetProperties: {
                    properties: { title: new_title },
                    fields: 'title'
                  }
                }] })
    end

    def update_survey_title(origin_id)
      google_api = Google::Api.new(@current_account['access_token'])
      survey = Google::SurveyMapper.new(google_api)
                                   .load(origin_id, @current_account)
      Repository::For[survey.class].update_title(survey)
    end
  end
end
