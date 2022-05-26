# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Usage: Service::UpdateVisualReport.new.call(redis: "...", visual_report_id: "...", spreadsheet_id: "...", config: <config>, acess_token)
    class UpdateVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :delete_visual_report_in_redis
      step :delete_source_in_redis

      private

      # input { redis:, visual_report_id:, spreadsheet_id: }
      def delete_visual_report_in_redis(input)
        input[:redis].delete("visual_report#{input[:spreadsheet_id]}")
        input[:redis].delete("all_graphs#{input[:spreadsheet_id]}")
        Success(input)
      rescue StandardError
        Failure('Failed to delete visual report and graph results.')
      end

      # input { redis:, visual_report_id:, spreadsheet_id: }
      def delete_source_in_redis(input)
        sources = input[:redis].get("source#{input[:spreadsheet_id]}")
        sources.each do |source|
          if source[0] == 'spreadsheet'
            url = source[1] # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
            other_sheet_id = url.match('.*/(.*)/')[1]
            input[:redis].delete("other_sheet#{other_sheet_id}")
          end
        end
        input[:redis].delete("source#{input[:spreadsheet_id]}")
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete source in redis.')
      end
    end
  end
end
