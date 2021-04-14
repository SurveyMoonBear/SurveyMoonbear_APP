# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a updated launch
    # Usage: Service::CloseSurvey.new.call(survey_id: "...")
    class CloseSurvey
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database
      step :change_survey_state
      step :change_launch_state

      private

      # input { survey_id: }
      def get_survey_from_database(input)
        db_survey = GetSurveyFromDatabase.new.call(survey_id: input[:survey_id])

        if db_survey.success?
          input[:db_survey] = db_survey.value!
          Success(input)
        else
          Failure(db_survey.failure)
        end
      end

      # input { ..., db_survey: }
      def change_survey_state(input)
        Repository::For[ input[:db_survey].class ].update_state(input[:db_survey])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to change survey state to closed.')
      end

      # input { ... }
      def change_launch_state(input)
        db_launch = Repository::For[Entity::Launch].find_id(input[:db_survey].launch_id)
        updated_launch = Repository::For[db_launch.class].update_state(db_launch)

        Success(updated_launch)
      rescue StandardError => e
        puts e
        Failure('Failed to change launch state to closed.')
      end
    end
  end
end
