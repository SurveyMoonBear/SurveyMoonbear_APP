# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetCurrentScore
      include Dry::Transaction
      include Dry::Monads

      step :get_current_score

      private

      def get_current_score(input)
        source1 = input[:source1]
        assignments = source1[1]
        scores = source1[0]
        student = []

        source1.each do |row|
          student = row if input[:email] == row[8]
        end

        ss = []
        total_score = 0
        my_total_score = 0
        assignments.each_with_index do |assignment, col|
          if (assignment.include?('HW') || assignment.include?('ST') || assignment.include?('PR') || assignment.include?('LA') || assignment.include?('QZ')) && assignment.length == 4 && !student[col].nil? && !student[col].empty?
            ss.append(assignment)
            total_score += scores[col].to_f
            my_total_score += student[col].to_f
          end
        end
        current_score = (my_total_score.to_f / total_score * 100).ceil.to_i.to_s + '%'
        Success(current_score)
      rescue StandardError => e
        Failure('Failed to get current score.')
      end
    end
  end
end
