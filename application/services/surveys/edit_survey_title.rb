# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  # Return editted survey entity of new title
  # Usage: EditSurveyTitle.new.call(current_account: {...}, survey_id: "...", new_title: "...")
  class EditSurveyTitle
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_origin_id
    step :update_spreadsheet_title
    step :update_survey_title

    def get_survey_origin_id(current_account:, survey_id:, new_title:)
      survey = Repository::For[Entity::Survey].find_id(survey_id)
      Success(current_account: current_account, 
              origin_id: survey.origin_id, new_title: new_title)
    rescue
      Failure('Failed to get survey origin id.')
    end

    def update_spreadsheet_title(current_account:, origin_id:, new_title:)
      update_res = Google::Api.new(current_account['access_token'])
                              .update_gs_title(origin_id, new_title)

      Success(current_account: current_account, origin_id: origin_id)
    rescue
      Failure("Failed to update spreadsheet title. #{update_res}")
    end

    def update_survey_title(current_account:, origin_id:)
      google_api = Google::Api.new(current_account['access_token'])
      survey = Google::SurveyMapper.new(google_api)
                                   .load(origin_id, current_account)
      updated_survey = Repository::For[survey.class].update_title(survey)
      Success(updated_survey)
    rescue
      Failure('Failed to update survey title in database')
    end
  end
end
