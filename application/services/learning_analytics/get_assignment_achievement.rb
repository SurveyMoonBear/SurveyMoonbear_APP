# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetAssignmentAchievementData
      include Dry::Transaction
      include Dry::Monads

      step :get_participation

      private

      # TODO: get number of "5" assignment
      def get_participation(input)
        source = input[:source]
        source.each do |row|
          return Success(row[53...55]) if input[:email] == row[8]
        end
        Failure('Failed to find achievement data.')
      rescue StandardError => e
        Failure('Failed to get achievement data.')
      end
    end
  end
end
