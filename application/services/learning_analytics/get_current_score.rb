# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetCurrentScore
      include Dry::Transaction
      include Dry::Monads

      step :get_current_score

      private

      def get_current_score(input)
        categorize_score_type = input[:categorize_score_type]

        score_type = ['total_score']
        data = categorize_score_type.select{|key, value| score_type.include? key }
        Success(data["total_score"][0]["score"])
      rescue StandardError => e
        puts "log[error]:current_score: #{e.full_message}"
        Failure('Failed to get current score.')
      end
    end
  end
end
