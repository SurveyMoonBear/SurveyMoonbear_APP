# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Usage: Service::UpdateVisualReport.new.call(redis: "...", visual_report_id: "...", spreadsheet_id: "...", config: <config>, acess_token)
    class UpdateVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :get_visual_report_owner_name
      step :delete_keys_in_redis
      step :transform_responses

      private

      # input { redis:, visual_report_id:, spreadsheet_id:... }
      def get_visual_report_owner_name(input)
        input[:visual_report] = Repository::For[Entity::VisualReport].find_id(input[:visual_report_id])
        input[:user_key] = input[:visual_report].owner.username + input[:spreadsheet_id]
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get visual report owner from db.')
      end

      # input { redis:, user_key:, ... }
      def delete_keys_in_redis(input)
        if input[:redis].get(input[:user_key])
          sources = input[:redis].get(input[:user_key])['source']
          sources.each do |source|
            if source[0] == 'spreadsheet' && source[1] != 'please enter a google spreadsheet link'
              url = source[1] # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
              gid = url.match('#gid=([0-9]+)')[1]
              other_sheet_id = url.match('.*/(.*)/')[1]
              other_sheet_key = source[2] + '/other_sheet' + other_sheet_id + 'gid' + gid
              input[:redis].delete(other_sheet_key)
            end
          end
          input[:redis].delete(input[:user_key])
        end
        Success(input)
      rescue StandardError
        Failure('Failed to delete source in redis.')
      end

      # input { redis:, visual_report:, spreadsheet_id:, access_token:, config:, user_key: }
      def transform_responses(input)
        responses = TransformVisualSheetsToChart.new.call(user_key: input[:user_key],
                                                          visual_report: input[:visual_report],
                                                          spreadsheet_id: input[:spreadsheet_id],
                                                          config: input[:config],
                                                          redis: input[:redis],
                                                          access_token: input[:access_token])
        if responses.success?
          input[:all_graphs] = responses.value!
          Success(input)
        else
          Failure(responses.failure)
        end
      end
    end
  end
end
