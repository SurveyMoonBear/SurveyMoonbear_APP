# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return updated survey entity
    # Usage: Service::UpdateSurveyOptions.new.call(survey_id: "...", option: "...", option_value: )
    class UpdateSurveyOptions
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database
      step :update_survey_options

      private

      # input {survey_id:, option:, option_value:}
      def get_survey_from_database(input)
        db_survey = GetSurveyFromDatabase.new.call(survey_id: input[:survey_id])

        if db_survey.success?
          input[:db_survey] = db_survey.value!
          Success(input)
        else
          Failure(db_survey.failure)
        end
      end

      # input {db_survey:}
      def update_survey_options(input)
        updated_survey = Repository::For[Entity::Survey].update_options(input[:db_survey], 
                                                                        input[:option], 
                                                                        input[:option_value])
        Success(updated_survey)
      rescue StandardError => e
        puts e
        Failure('Failed to update survey option, ' + input[:option])
      end
    end
  end
end
