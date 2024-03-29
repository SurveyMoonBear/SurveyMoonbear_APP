# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted study entity of new title
    # Usage: Service::AddExistSurvey.new.call(study_id: "...", survey_id: "...")
    class AddExistSurvey
      include Dry::Transaction
      include Dry::Monads

      step :add_exist_survey

      private

      # input { study_id:, survey_id: }
      def add_exist_survey(input)
        survey = Repository::For[Entity::Study].add_survey(input[:study_id], input[:survey_id])
        Success(survey)
      rescue
        Failure('Failed to add an exist survey into study.')
      end
    end
  end
end
