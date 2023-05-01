# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetWeeklyParticipation
      include Dry::Transaction
      include Dry::Monads

      step :get_participation

      private

      # input { all_graphs:, case_email:, redis:, user_key:}
      def get_participation(input)
        source = input[:source]
        source.each do |row|
          return Success(row[4...22]) if input[:email] == row[2]
        end
        Failure('Failed to find participation.')
      rescue StandardError => e
        Failure('Failed to get participation.')
      end
    end
  end
end
