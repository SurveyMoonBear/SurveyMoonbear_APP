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
        result = if input[:dashboard_type] == 'participation_checklist'
                   Service::GetWeeklyParticipation.new.call(source: values['source2'], email: input[:email])
                 elsif input[:dashboard_type] == 'assignment_achievement'
                   Service::GetAssignmentAchievementData.new.call(source1: values['source1'], source3: values['source3'], email: input[:email]) 
                 end
        Success(result.value!)
      rescue StandardError => e
        Failure('Failed to get sources from redis.')
      end
    end
  end
end
