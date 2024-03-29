# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # get student's sequence and existence in the original sheet.

    class GetStudentSequence
      include Dry::Transaction
      include Dry::Monads

      step :get_student_sequence

      private

      def get_student_sequence(input)
        categorize_score_type = input[:categorize_score_type]
        score_type = categorize_score_type.keys[0]
        # my_student_id = categorize_score_type["achievement"][0]["student_id"]
        my_student_id = categorize_score_type[score_type][0]["student_id"]
        student_index = -1
        # categorize_score_type["achievement"][0]["all_name"].keys.each_with_index do |student_id, index|
        categorize_score_type[score_type][0]["all_name"].keys.each_with_index do |student_id, index|
          if student_id == my_student_id
            student_index = index
          end
        end

        if student_index == -1
          return Failure('Can not find your email')
        end

        result = student_index
        Success(result)
      rescue StandardError => e
        Failure('Failed to get student sequence.')
      end
    end
  end
end
