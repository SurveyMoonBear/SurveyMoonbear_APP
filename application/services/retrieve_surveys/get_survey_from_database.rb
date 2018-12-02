# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return an entity of survey from database
    # Usage: Service::GetSurveyFromDatabase.new.call(survey_id: "...")
    class GetSurveyFromDatabase
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database

      private

      # input :survey_id
      def get_survey_from_database(input)
        survey = Repository::For[Entity::Survey].find_id(input[:survey_id])
        raise unless survey
        
        Success(survey)
      rescue
        Failure('Failed to get survey from database.')
      end
    end
  end
end
