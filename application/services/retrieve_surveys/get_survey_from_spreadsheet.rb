# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a survey entity from spreadsheet
    # Usage: Service::GetSurveyFromSpreadsheet.new.call(spreadsheet_id: "...", access_token: "...", owner: <account_entity or current_account>)
    class GetSurveyFromSpreadsheet
      include Dry::Transaction
      include Dry::Monads

      step :read_spreadsheet

      private

      # input { spreadsheet_id:, current_account: }
      def read_spreadsheet(input)
        sheets_api = Google::Api::Sheets.new(input[:access_token])
        spreadsheet = Google::SurveyMapper.new(sheets_api).load(input[:spreadsheet_id], input[:owner])

        Success(spreadsheet)
      rescue StandardError => e
        puts e
        Failure('Failed to read spreadsheet survey.')
      end
    end
  end
end
