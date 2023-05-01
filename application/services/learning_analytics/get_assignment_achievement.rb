# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetAssignmentAchievementData
      include Dry::Transaction
      include Dry::Monads

      step :get_achievement

      private

      # TODO: get number of "5" assignment
      def get_achievement(input)
        source1 = input[:source1]
        source3 = input[:source3]
        # Homework > 5
        hw_column = []
        pr_column = []
        source1[1].each_with_index do |row, index|
          hw_column.append(index) if row.include? 'HW'
          pr_column.append(index) if row.include? 'PR'
        end

        individual_data = []
        source1.each do |row|
          individual_data = row if input[:email] == row[8]
        end

        hw_excellent_count = 0
        hw_column.each do |hw|
          hw_excellent_count += 1 if individual_data[hw] == '5'
        end

        # Peer review < 1, < 2
        pr_miss_count = 0
        pr_column.each do |pr|
          pr_miss_count += 1 if individual_data[pr] == '0'
        end

        # Help
        help_count = 0
        source3.each do |row|
          help_count = row[-1].to_i if input[:email] == row[2]
        end

        achievement_result = {}
        achievement_result['hw'] = []
        achievement_result['pr'] = []
        achievement_result['help'] = []

        hw = hw_excellent_count > 3 ? 3 : hw_excellent_count
        pr = pr_miss_count > 3 ? 0 : 3 - pr_miss_count

        for i in 1..3 do
          if hw > 0
            achievement_result['hw'].append('1')
            hw -= 1
          else
            achievement_result['hw'].append('0')
          end

          if pr > 0
            achievement_result['pr'].append('1')
            pr -= 1
          else
            achievement_result['pr'].append('0')
          end

          if help_count > 0
            achievement_result['help'].append('1')
            help_count -= 1
          else
            achievement_result['help'].append('0')
          end
          binding.irb
        end
        Success(achievement_result)
      rescue StandardError => e
        Failure('Failed to get achievement data.')
      end
    end
  end
end
