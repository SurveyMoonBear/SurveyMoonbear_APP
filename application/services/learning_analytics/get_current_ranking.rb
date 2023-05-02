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
        source1 = input[:source1]
        ranking = []
        source1.each do |source|
          ranking.append({ "name": source[3], "email": source[8], "score": source[56].delete('%').to_f }) unless source[1].nil? || source[1].empty? || !source[56].include?('%')
        end
        sorted_ranking = ranking.sort_by { |sequence| sequence[:score] }.reverse

        # sequence / total student
        rank = 0
        sorted_ranking.each_with_index do |row, idx|
          rank = idx + 1 if input[:email] == row[:email]
        end

        class_percentile = (rank.to_f / sorted_ranking.length * 100).ceil.to_i.to_s + '%'
        Success(class_percentile)
      rescue StandardError => e
        Failure('Failed to get ranking.')
      end
    end
  end
end
