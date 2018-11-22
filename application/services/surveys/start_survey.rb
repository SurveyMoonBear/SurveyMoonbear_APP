# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # Return a updated survey
  # Usage: StartSurvey.new.call(survey_id: "...", current_account: {...})
  class StartSurvey
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :get_survey_from_spreadsheet
    step :store_survey_into_database_and_launch

    def get_survey_from_database(survey_id:, current_account:)
      saved_survey = GetSurveyFromDatabase.new.call(survey_id: survey_id)
      Success(saved_survey: saved_survey.value!, current_account: current_account)
    rescue
      Failure('Failed to get survey from database.')
    end

    def get_survey_from_spreadsheet(saved_survey:, current_account:)
      new_survey = GetSurveyFromSpreadsheet.new.call(spreadsheet_id: saved_survey.origin_id, 
                                                     current_account: current_account)
      Success(new_survey: new_survey.value!)
    rescue
      Failure('Failed to get survey from spreadsheet.')
    end

    def store_survey_into_database_and_launch(new_survey:)
      started_survey = Repository::For[new_survey.class].add_launch(new_survey)
      Success(started_survey)
    rescue
      Failure('Failed to store the new survey into database and launch.')
    end
  end
end
