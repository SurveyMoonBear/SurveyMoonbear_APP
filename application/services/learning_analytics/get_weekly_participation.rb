# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetWeeklyParticipation
      include Dry::Transaction
      include Dry::Monads

      step :get_participation

      private

      # input { all_graphs:, case_email:, redis:, user_key:}
      def get_participation(input)
        categorize_score_type = input[:categorize_score_type]

        score_type = ['discuss']
        data = categorize_score_type.select{|key, value| score_type.include? key }
        binding.irb
        result = []
        data["discuss"].each do |discuss|
          result.append(discuss["score"])
        end
        Success(result)
      rescue StandardError => e
        Failure('Failed to get participation.')
      end
    end
  end
end
