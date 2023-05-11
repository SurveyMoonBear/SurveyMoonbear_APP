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
        other_sheets_keys = input[:redis].get_set(input[:visual_report_id])
        values = {}
        other_sheets_keys.each do |key|
          source = key.split('/')[0]
          values[source] = input[:redis].get(key)
        end
        source1 = values['source1']
        student_index = 0

        source1.each_with_index do |row, index|
          student_index = index - 2 if input[:email] == row[8]
        end

        student_index %= 8
        category_one = 'My Learning Report'
        category_two = 'My Participation'

        category = []
        dashboard = []
        my_assignments_report = ['My Assignments Report', 'My weekly assignment score', 'assignments_report', 'Assignments Report']
        current_score = ['Current score', 'My current score', 'current_score', 'Current Score']
        my_participation_checklist = ['My Participation Checklist', 'See if you participate on Teams every week', 'participation_checklist', 'Participation Checklist']
        assignment_achievement = ['Assignment Achievement', 'Achievements of homework, peer review, and help', 'assignment_achievement', 'Assignment Achievement']
        teams_discussion_leaderboard = ['Teams Discussion Leaderboard', 'Top 10 active students on Teams', 'discuss_leaderboard', 'Discussion Leaderboard']
        teams_help_leaderboard = ['Teams Help Leaderboard', 'Top 25 helpful students on Teams', 'help_leaderboard', 'Help Leaderboard']
        assignment_distribution = ['Assignment Distribution', 'My score compares with other students', 'assignments_distribution', 'Assignments Distribution']
        current_ranking = ['Current Ranking', 'My current standing in the class', 'current_ranking', 'Current Ranking']

        if student_index < 4 
          category = [category_one, category_two]
          if student_index == 0
            dashboard = [[my_assignments_report, current_score, my_participation_checklist, assignment_achievement], 
                         [teams_discussion_leaderboard, teams_help_leaderboard, assignment_distribution,current_ranking]]
          elsif student_index == 1
            dashboard = [[current_score, my_participation_checklist, assignment_achievement, my_assignments_report], 
                         [teams_help_leaderboard, assignment_distribution,current_ranking, teams_discussion_leaderboard]]
          elsif student_index == 2
            dashboard = [[my_participation_checklist, assignment_achievement, my_assignments_report, current_score],
                         [assignment_distribution,current_ranking, teams_discussion_leaderboard, teams_help_leaderboard]]
          elsif student_index == 3
            dashboard = [[assignment_achievement, my_assignments_report, current_score, my_participation_checklist],
                         [current_ranking, teams_discussion_leaderboard, teams_help_leaderboard, assignment_distribution]]
          end
        else
          category = [category_two, category_one]
          if student_index == 4
            dashboard = [[assignment_distribution, current_ranking, teams_help_leaderboard, teams_discussion_leaderboard],
                         [assignment_achievement, my_assignments_report, my_participation_checklist, current_score]]
          elsif student_index == 5
            dashboard = [[current_ranking, teams_help_leaderboard, teams_discussion_leaderboard, assignment_distribution],
                         [my_assignments_report, my_participation_checklist, current_score, assignment_achievement]]
          elsif student_index == 6
            dashboard = [[teams_help_leaderboard, teams_discussion_leaderboard, assignment_distribution, current_ranking],
                         [my_participation_checklist, current_score, assignment_achievement, my_assignments_report]]
          elsif student_index == 7
            dashboard = [[teams_discussion_leaderboard, assignment_distribution, current_ranking, teams_help_leaderboard],
                         [current_score, assignment_achievement, my_assignments_report, my_participation_checklist]]
          end
        end

        result = { "category": category, "dashboard": dashboard }
        Success(result)
      rescue StandardError => e
        binding.irb
        Failure('Failed to get dashboard group.')
      end
    end
  end
end
