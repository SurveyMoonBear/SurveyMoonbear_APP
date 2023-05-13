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
        categorize_score_type = input[:categorize_score_type]
        result = if input[:dashboard_type] == 'participation_checklist'
                   Service::GetWeeklyParticipation.new.call(email: input[:email], categorize_score_type: categorize_score_type)
                 elsif input[:dashboard_type] == 'assignment_achievement'
                   Service::GetAssignmentAchievementData.new.call(email: input[:email], categorize_score_type: categorize_score_type) 
                 elsif input[:dashboard_type].include?('leaderboard')
                   Service::GetHelpLeaderboard.new.call(categorize_score_type: categorize_score_type, dashboard_type: input[:dashboard_type])
                 elsif input[:dashboard_type] == 'current_ranking'
                   Service::GetCurrentRanking.new.call(email: input[:email], categorize_score_type: categorize_score_type)
                 elsif input[:dashboard_type] == 'current_score'
                   Service::GetCurrentScore.new.call(email: input[:email], categorize_score_type: categorize_score_type)
                 elsif input[:dashboard_type] == 'assignments_distribution'
                   Service::GetAssignmentsDistribution.new.call(email: input[:email], categorize_score_type: categorize_score_type)
                 elsif input[:dashboard_type] == 'assignments_report'
                   Service::GetAssignmentsReport.new.call(email: input[:email], categorize_score_type: categorize_score_type)
                 end
        Success(result.value!)
      rescue StandardError => e
        Failure('Failed to get sources from redis.')
      end
    end
  end
end
