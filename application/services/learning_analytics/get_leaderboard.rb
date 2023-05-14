# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetLeaderboard
      include Dry::Transaction
      include Dry::Monads

      step :get_leaderboard

      private

      # TODO: get number of "5" assignment
      def get_leaderboard(input)
        categorize_score_type = input[:categorize_score_type]
        dashboard_type = input[:dashboard_type]

        score_type = [dashboard_type]
        data = categorize_score_type.select{|key, value| score_type.include? key }
        # rearrange the order of the top 25
        sorted_order = data[dashboard_type][0]["all_scores"].sort_by {|k, v| v.to_i}.reverse
        # return an array with the name and count
        params = data[dashboard_type][0]["params"].to_i
        top_scores = sorted_order.take(params)

        all_name = data.first[1][0]["all_name"]
        top = []
        top_scores.each do |score|
          id = score[0]
          name = all_name[id]
          top.append([name, score[1]])
        end
        Success(top)
      rescue StandardError => e
        Failure('Failed to get help leaderboard data.')
      end
    end
  end
end
