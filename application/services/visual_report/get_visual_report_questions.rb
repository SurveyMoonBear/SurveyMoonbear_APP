# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::GetVisualReportQuestions.new.call(config: <config>, current_account: {...}, title: "...", sources:)
    class GetVisualReportQuestions
      include Dry::Transaction
      include Dry::Monads

      step :get_questions_from_db
      step :question_data_validation

      private

      # input { config:, current_account:, title: }
      def get_questions_from_db(input)
        input[:current_account]['access_token'] = Google::Auth.new(input[:config]).refresh_access_token

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      def question_data_validation(input)


        Success(input[:new_sheet].value!)
      rescue StandardError => e
        puts e
        Failure('Failed to set data validation.')
      end
    end
  end
end
