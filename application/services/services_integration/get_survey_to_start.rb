require 'dry/transaction'

module SurveyMoonbear
  class GetSurveyToStart
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :get_survey_from_spreadsheet
    step :start_survey

    def get_survey_from_database(survey_id)
      saved_survey = GetSurveyFromDatabase.new.call(survey_id)
      Success(saved_survey)
    rescue
      Failure('Failed to get survey from database.')
    end

    def get_survey_from_spreadsheet(saved_survey, current_account)
      new_survey = GetSurveyFromSpreadsheet.new(current_account)
                                           .call(saved_survey.origin_id)
      Success(new_survey)
    rescue
      Failure('Failed to get survey from spreadsheet.')
    end

    def start_survey(new_survey)
      started_survey = StartSurvey.new.call(new_survey)
      Success(started_survey)
    rescue
      Failure('Failed to start survey.')
    end
  end
end