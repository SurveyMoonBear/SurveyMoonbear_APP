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
        other_sheets_keys = input[:redis].get_set(input[:visual_report_id])
        values = {}
        other_sheets_keys.each do |key|
          source = key.split('/')[0]
          values[source] = input[:redis].get(key)
        end
        source1 = values['source1']
        student_index = -1

        source1.each_with_index do |row, index|
          next unless Email.new().is_valid?(row[8])
          student_index = index - 2 if input[:email] == row[8].downcase
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
