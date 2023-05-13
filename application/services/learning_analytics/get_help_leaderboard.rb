# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetHelpLeaderboard
      include Dry::Transaction
      include Dry::Monads

      step :get_all_help_count

      private

      # TODO: get number of "5" assignment
      def get_all_help_count(input)
        categorize_score_type = input[:categorize_score_type]
        dashboard_type = input[:dashboard_type]

        score_type = [dashboard_type]
        data = categorize_score_type.select{|key, value| score_type.include? key }
        # rearrange the order of the top 25
        sorted_order = data[dashboard_type][0]["all_scores"].sort_by {|k, v| v.to_i}.reverse
        # return an array with the name and count
        params = data[dashboard_type][0]["params"].to_i
        top_helpful = sorted_order.take(params)

        Success(top_helpful)
      rescue StandardError => e
        Failure('Failed to get help leaderboard data.')
      end
    end
  end
end
