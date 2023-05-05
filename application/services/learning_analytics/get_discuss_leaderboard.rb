# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetDiscussLeaderboard
      include Dry::Transaction
      include Dry::Monads

      step :get_all_discuss_count

      private

      def get_all_discuss_count(input)
        source1 = input[:source1]
        discuss_order = []
        source1.each do |source|
          discuss_order.append({ "name": source[3], "discuss_count": source[54] })
        end
        sorted_discuss_order = discuss_order.sort_by { |sequence| sequence[:discuss_count].to_i }.reverse
        top_active = sorted_discuss_order.take(10)
        Success(top_active)
      rescue StandardError => e
        Failure('Failed to get discussion leaderboard data.')
      end
    end
  end
end
