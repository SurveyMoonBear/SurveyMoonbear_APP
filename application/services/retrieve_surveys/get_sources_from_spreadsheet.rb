# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return sources entity from spreadsheet
    # Usage: Service::GetSourcesFromSpreadsheet.new.call(spreadsheet_id: "...", access_token: "...", redis:"...")
    class GetSourcesFromSpreadsheet
      include Dry::Transaction
      include Dry::Monads

      step :read_spreadsheet

      private

      # input { spreadsheet_id:, current_account: }
      def read_spreadsheet(input)
        key = 'source' + input[:spreadsheet_id]

        sheets_api = Google::Api::Sheets.new(input[:access_token])
        sources = Google::SourceMapper.new(sheets_api).load_several(input[:spreadsheet_id],
                                                                    'sources',
                                                                    input[:redis],
                                                                    key)

        Success(sources)
      rescue StandardError => e
        puts e
        Failure('Failed to read spreadsheet visual report table source.')
      end
    end
  end
end
