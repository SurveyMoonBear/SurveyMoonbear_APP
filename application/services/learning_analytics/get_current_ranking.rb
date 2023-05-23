# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetCurrentRanking
      include Dry::Transaction
      include Dry::Monads

      step :get_ranking

      private

      def get_ranking(input)
        categorize_score_type = input[:categorize_score_type]

        score_type = ['percentile']
        data = categorize_score_type.select{|key, value| score_type.include? key }
        Success(data["percentile"][0]["score"])
      rescue StandardError => e
        puts "log[error]:percentile_ranking: #{e.full_message}"
        Failure('Failed to get ranking.')
      end
    end
  end
end
