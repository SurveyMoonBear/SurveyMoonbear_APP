# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # Return a updated survey
  # Usage: StartSurvey.new.call(survey: <survey_entity>)
  class StartSurvey
    include Dry::Transaction
    include Dry::Monads

    step :store_survey_into_database_and_launch

    def store_survey_into_database_and_launch(survey:)
      started_survey = Repository::For[survey.class].add_launch(survey)
      Success(started_survey)
    rescue
      Failure('Failed to store survey into database and launch.')
    end
  end
end
