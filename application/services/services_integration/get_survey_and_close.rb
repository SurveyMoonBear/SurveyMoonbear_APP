require 'dry/transaction'

module SurveyMoonbear
  class GetSurveyAndClose
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :close_survey

    def get_survey_from_database(survey_id)
      saved_survey = GetSurveyFromDatabase.new.call(survey_id)
      Success(saved_survey)
    rescue
      Failure('Failed to get survey from database.')
    end

    def close_survey(saved_survey)
      closed_survey = CloseSurvey.new.call(saved_survey)
      Success(closed_survey)
    rescue
      Failure('Failed to close survey.')
    end
  end
end