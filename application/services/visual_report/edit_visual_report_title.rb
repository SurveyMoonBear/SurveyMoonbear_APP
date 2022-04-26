# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted visual report entity of new title
    # Usage: Service::EditVisualReportTitle.new.call(current_account: {...}, visual_report_id: "...", new_title: "...")
    class EditVisualReportTitle
      include Dry::Transaction
      include Dry::Monads

      step :get_visual_report_origin_id
      step :update_spreadsheet_title
      step :update_visual_report_title

      private

      # input { current_account:, visual_report_id:, new_title: }
      def get_visual_report_origin_id(input)
        visual_report = Repository::For[Entity::VisualReport].find_id(input[:visual_report_id])

        input[:origin_id] = visual_report.origin_id
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get visual report origin id.')
      end

      # input { ..., origin_id: }
      def update_spreadsheet_title(input)
        Google::Api::Sheets.new(input[:current_account]['access_token'])
                           .update_gs_title(input[:origin_id], input[:new_title])
        Success(input)
      rescue
        Failure("Failed to update spreadsheet title.")
      end

      # input { ... }
      def update_visual_report_title(input)
        sheets_api = Google::Api::Sheets.new(input[:current_account]['access_token'])
        visual_report = Google::VisualReportMapper.new(sheets_api)
                                                  .load(input[:origin_id], input[:current_account])

        updated_visual_report = Repository::For[visual_report.class].update_title(visual_report)
        Success(updated_visual_report)
      rescue
        Failure('Failed to update visual report title in database')
      end
    end
  end
end
