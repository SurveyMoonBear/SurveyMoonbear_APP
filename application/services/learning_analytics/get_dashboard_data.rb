# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetDashboardData
      include Dry::Transaction
      include Dry::Monads

      step :get_sources_from_redis

      private

      # input { all_graphs:, case_email:, redis:, user_key:}
      def get_sources_from_redis(input)
        other_sheets_keys = input[:redis].get_set(input[:visual_report_id])
        values = {}
        other_sheets_keys.each do |key|
          source = key.split('/')[0]
          values[source] = input[:redis].get(key)
        end
        Success(values)
      rescue StandardError => e
        Failure('Failed to get sources from redis.')
      end
    end
  end
end
