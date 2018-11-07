# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # To get survey from spreadsheet, and start it
  # Usage: GetSurveyToStart.new.call(survey_id: "...", current_account: {...})
  class GetSurveyToStart
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :get_survey_from_spreadsheet
    step :start_survey

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

    def start_survey(new_survey:)
      started_survey = StartSurvey.new.call(survey: new_survey)
      Success(started_survey.value!)
    rescue
      Failure('Failed to start survey.')
    end
  end
end