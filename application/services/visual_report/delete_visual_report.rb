# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted visual report
    # Usage: Service::DeleteVisualReport.new.call(config: <config>, visual_report_id: "...")
    class DeleteVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :refresh_access_token
      step :delete_record_in_database
      step :delete_spreadsheet

      private

      # input { config:, visual_report_id: }
      def refresh_access_token(input)
        input[:access_token] = Google::Auth.new(input[:config]).refresh_access_token
        Success(input)
      rescue
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      # input { ..., access_token }
      def delete_record_in_database(input)
        input[:deleted_visual_report] = Repository::For[Entity::VisualReport].delete_from(input[:visual_report_id])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete record in database.')
      end

      # input { ..., deleted_visual_report: }
      def delete_spreadsheet(input)
        GoogleSpreadsheet.new(input[:access_token])
                         .delete_spreadsheet(input[:deleted_visual_report].origin_id)
        Success(input[:deleted_visual_report])
      rescue StandardError => e
        puts e
        Failure('Failed to delete spreadsheet.')
      end
    end
  end
end
