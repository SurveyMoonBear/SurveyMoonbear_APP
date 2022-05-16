# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::GetCustomizedVisualReport.new.call(config: ..., visual_report_id:..., spreadsheet_id:..., code: ..., access_token:...)
    class GetCustomizedVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :get_refresh_and_access_token
      step :get_google_account
      step :transfer_responses

      private

      # input { config:, code:}
      def get_refresh_and_access_token(input)
        input[:acc_access_token] = Google::Auth.new(input[:config])
                                               .get_access_token(input[:code], input[:visual_report_id], input[:spreadsheet_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      # input { config:, code:, tokens}
      def get_google_account(input)
        google_account = Google::Auth.new(input[:config])
                                     .get_google_account(input[:acc_access_token]) # accunt access token
        input[:email] = google_account['email']

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get google account.')
      end

      def transfer_responses(input)
        responses = TransformVisualSheetsToHTMLWithCase.new
                                                       .call(config: input[:config],
                                                             spreadsheet_id: input[:spreadsheet_id],
                                                             case_email: input[:email],
                                                             access_token: input[:access_token]) # moonbear access token
        if responses.success?
          Success(responses.value!)
        else
          Failure(responses.failure)
        end
      end
    end
  end
end
