# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    class CreateRandomUrl
      include Dry::Transaction
      include Dry::Monads

      step :get_owned_surveys
      step :generate_random_survey
     
      # input { study_id: }
      def get_owned_surveys(input)
        surveys = Repository::For[Entity::Survey].find_study(input[:study_id])
        input[:survey_url] = []
        surveys.map do |survey|
          input[:survey_url].push(("/onlinesurvey/#{survey.id}/#{survey.launch_id}"))
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get survey details from database.')
      end

      # input { study_id:, waves: }
      def generate_random_survey(input)
        input[:survey_url] = input[:survey_url][(rand() * input[:survey_url].length).floor()]
        Success(input) # input { study_id:, waves:, participants: }
      rescue StandardError => e
        puts e
        Failure('Failed to get participants from database.')
      end
    end
  end
end
