# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Split students into 8 groups

    class GetDashboardGroup
      include Dry::Transaction
      include Dry::Monads

      step :get_dashboard_group

      private

      def get_dashboard_group(input)
        student_index = input[:student_sequence] % 8
        category_one = 'My Learning Report'
        category_two = 'Participation'

        category = []
        dashboard = []
        my_assignments_report = ['My Assignments Report', 'My weekly assignment score', 'assignments_report', 'My Assignments Report']
        current_score = ['Current score', 'My total score so far', 'current_score', 'Current Score']
        my_participation_checklist = ['Meaningful Participation on MS Teams', 'Which week you participate on MS Teams', 'participation_checklist', 'My Participation on MS Teams']
        assignment_achievement = ['Class Achievement', 'How well are your assignments, and how regular you submit review and help others', 'assignment_achievement', 'Class Achievement']
        teams_discussion_leaderboard = ['Online Discussion Leaderboard', 'Top participants on MS Teams', 'discuss_leaderboard', 'Teams Discussion Leaderboard']
        teams_help_leaderboard = ['Teams Help Leaderboard', 'Most often credited on help assignment', 'help_leaderboard', 'Teams Help Leaderboard']
        assignment_distribution = ['Assignments Distribution', 'My score compares with other students', 'assignments_distribution', 'Assignments Distribution']
        current_ranking = ['Performance Percentile', 'My Class Standing in the Percentile', 'current_ranking', 'Performance Percentile']

        category = [category_one, category_two]
        dashboard = [[assignment_distribution, assignment_achievement], [my_participation_checklist, teams_discussion_leaderboard]]
        # if student_index < 4
        #   category = [category_one, category_two]
        #   if student_index == 0
        #     dashboard = [[my_assignments_report, current_score, my_participation_checklist, assignment_achievement],
        #                  [teams_discussion_leaderboard, teams_help_leaderboard, assignment_distribution,current_ranking]]
        #   elsif student_index == 1
        #     dashboard = [[current_score, my_participation_checklist, assignment_achievement, my_assignments_report],
        #                  [teams_help_leaderboard, assignment_distribution,current_ranking, teams_discussion_leaderboard]]
        #   elsif student_index == 2
        #     dashboard = [[my_participation_checklist, assignment_achievement, my_assignments_report, current_score],
        #                  [assignment_distribution,current_ranking, teams_discussion_leaderboard, teams_help_leaderboard]]
        #   elsif student_index == 3
        #     dashboard = [[assignment_achievement, my_assignments_report, current_score, my_participation_checklist],
        #                  [current_ranking, teams_discussion_leaderboard, teams_help_leaderboard, assignment_distribution]]
        #   end
        # else
        #   category = [category_two, category_one]
        #   if student_index == 4
        #     dashboard = [[assignment_distribution, current_ranking, teams_help_leaderboard, teams_discussion_leaderboard],
        #                  [assignment_achievement, my_assignments_report, my_participation_checklist, current_score]]
        #   elsif student_index == 5
        #     dashboard = [[current_ranking, teams_help_leaderboard, teams_discussion_leaderboard, assignment_distribution],
        #                  [my_assignments_report, my_participation_checklist, current_score, assignment_achievement]]
        #   elsif student_index == 6
        #     dashboard = [[teams_help_leaderboard, teams_discussion_leaderboard, assignment_distribution, current_ranking],
        #                  [my_participation_checklist, current_score, assignment_achievement, my_assignments_report]]
        #   elsif student_index == 7
        #     dashboard = [[teams_discussion_leaderboard, assignment_distribution, current_ranking, teams_help_leaderboard],
        #                  [current_score, assignment_achievement, my_assignments_report, my_participation_checklist]]
        #   end
        # end

        result = { "category": category, "dashboard": dashboard }
        Success(result)
      rescue StandardError => e
        Failure('Failed to get dashboard group.')
      end
    end
  end
end
