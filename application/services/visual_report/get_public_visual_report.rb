# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::GetPublicVisualReport.new.call(config: ..., visual_report_id:..., spreadsheet_id:..., access_token:...)
    class GetPublicVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :get_visual_report_owner_name
      step :transform_responses
      step :transform_charts_to_html

      private

      def get_visual_report_owner_name(input)
        input[:user_key] = input[:visual_report].owner.username + input[:spreadsheet_id]

        Success(input)
      rescue StandardError
        Failure('Failed to get visual report owner from db.')
      end

      # input { visual_report:, spreadsheet_id:, access_token:, config:, user_key: }
      def transform_responses(input)
        redis = RedisCloud.new(input[:config])
        responses = TransformVisualSheetsToChart.new.call(user_key: input[:user_key],
                                                          visual_report: input[:visual_report],
                                                          spreadsheet_id: input[:spreadsheet_id],
                                                          config: input[:config],
                                                          redis: redis,
                                                          access_token: input[:access_token])
        if responses.success?
          input[:all_graphs] = responses.value!
          Success(input)
        else
          Failure(responses.failure)
        end
      end

      def transform_charts_to_html(input)
        transform_result = TransformResponsesToHTMLWithChart.new.call(pages_charts: input[:all_graphs])
        if transform_result.success?
          Success(all_graphs: input[:all_graphs],
                  nav_tab: transform_result.value![:nav_tab],
                  nav_item: transform_result.value![:nav_item],
                  pages_chart_val_hash: transform_result.value![:pages_chart_val_hash])
        else
          Failure(transform_result.failure)
        end
      end
    end
  end
end
