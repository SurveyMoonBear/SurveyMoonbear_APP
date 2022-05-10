# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted study entity of new title
    # Usage: Service::RemoveSurvey.new.call(study_id: "...", survey_id: "...")
    class RemoveSurvey
      include Dry::Transaction
      include Dry::Monads

      step :add_exist_survey

      private

      # input { study_id:, survey_id: }
      def add_exist_survey(input)
        study = Repository::For[Entity::Study].remove_survey(input[:study_id], input[:survey_id])
        Success(study)
      rescue
        Failure('Failed to remove survey from study.')
      end
    end
  end
end
