# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::GetCustomizedVisualReport.new.call(config: ..., visual_report_id:..., visual_repor:..., spreadsheet_id:..., code: ..., access_token:...)
    class GetCustomizedVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :get_refresh_and_access_token
      step :get_google_account
      step :get_visual_report_owner_name
      step :transform_responses
      step :self_comparison
      step :transform_charts_to_html

      private

      # input { config:, code:}
      def get_refresh_and_access_token(input)
        input[:acc_access_token] = Google::Auth.new(input[:config])
                                               .get_access_token(input[:code])

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

      def get_visual_report_owner_name(input)
        input[:user_key] = input[:visual_report].owner.username + input[:spreadsheet_id]

        Success(input)
      rescue StandardError
        Failure('Failed to get visual report owner from db.')
      end

      def transform_responses(input)
        redis = RedisCache.new(input[:config])
        responses = TransformVisualSheetsToChart.new.call(user_key: input[:user_key],
                                                          visual_report: input[:visual_report],
                                                          spreadsheet_id: input[:spreadsheet_id],
                                                          config: input[:config],
                                                          redis: redis,
                                                          access_token: input[:access_token])# moonbear access token
        if responses.success?
          input[:origin_all_graphs] = responses.value!
          Success(input)
        else
          Failure(responses.failure)
        end
      end

      def self_comparison(input)
        redis = RedisCache.new(input[:config])
        responses = TransformPublicToCustomizedReport.new
                                                     .call(all_graphs: input[:origin_all_graphs],
                                                           case_email: input[:email],
                                                           redis: redis,
                                                           user_key: input[:user_key],
                                                           spreadsheet_id: input[:spreadsheet_id])

        if responses.success?
          input[:all_graphs] = responses.value!
          Success(input)
        else
          Failure(responses.failure)
        end
      end

      # input { all_graphs:, .... }
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
