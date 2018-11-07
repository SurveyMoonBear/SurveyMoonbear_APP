# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # Return an entity of survey from database
  # Usage: GetSurveyFromDatabase.new.call(survey_id: "...")
  class GetSurveyFromDatabase
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database

    def get_survey_from_database(survey_id:)
      survey = Repository::For[Entity::Survey].find_id(survey_id)
      raise unless survey
      Success(survey)
    rescue
      Failure('Failed to get survey from database.')
    end
  end
end
