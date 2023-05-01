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
        source1 = input[:source1]
        help_order = []
        source1.each_with_index do |source, index|
          help_order.append({ "name": source[3], "help_count": source[53] })
        end
        # rearrange the order of the top 25
        sorted_help_order = help_order.sort_by { |sequence| sequence[:help_count].to_i }.reverse
        # return an array with the name and count
        top_helpful = sorted_help_order.take(25)

        Success(top_helpful)
      rescue StandardError => e
        Failure('Failed to get help leaderboard data.')
      end
    end
  end
end
