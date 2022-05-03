# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a visual report page entity from spreadsheet
    # Usage: Service::GetVisualreportFromSpreadsheet.new.call(spreadsheet_id: "...", access_token: "...", owner: <account_entity or current_account>)
    class GetVisualreportFromSpreadsheet
      include Dry::Transaction
      include Dry::Monads

      step :read_spreadsheet

      private

      # input { spreadsheet_id:, current_account: }
      def read_spreadsheet(input)
        sheets_api = Google::Api::Sheets.new(input[:access_token])
        spreadsheet = Google::VisualReportItemMapper.new(sheets_api).load_several(input[:spreadsheet_id])

        Success(spreadsheet)
      rescue StandardError => e
        puts e
        Failure('Failed to read spreadsheet visual report.')
      end
    end
  end
end
