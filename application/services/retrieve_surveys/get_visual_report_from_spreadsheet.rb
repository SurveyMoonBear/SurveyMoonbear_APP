# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a visual report page entity from spreadsheet
    # Usage: Service::GetVisualreportFromSpreadsheet.new.call(spreadsheet_id: "...", access_token: "...", redis: "...")
    class GetVisualreportFromSpreadsheet
      include Dry::Transaction
      include Dry::Monads

      step :read_spreadsheet

      private

      # input { spreadsheet_id:, access_token:, redis: }
      def read_spreadsheet(input)
        key = 'visual_report' + input[:spreadsheet_id]

        sheets_api = Google::Api::Sheets.new(input[:access_token])
        spreadsheet = Google::VisualReportItemMapper.new(sheets_api)
                                                    .load_several(input[:spreadsheet_id],
                                                                  input[:redis],
                                                                  key)

        Success(spreadsheet)
      rescue StandardError => e
        puts e
        Failure('Failed to read spreadsheet visual report.')
      end
    end
  end
end
