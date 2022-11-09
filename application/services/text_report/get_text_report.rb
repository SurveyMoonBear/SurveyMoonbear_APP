# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::GetTextReport.new.call(config: ..., visual_report_id:..., visual_repor:..., spreadsheet_id:..., code: ..., access_token:...)
    class GetTextReport
      include Dry::Transaction
      include Dry::Monads

      step :get_visual_report_owner_name
      step :transform_responses
      step :self_comparison_text_score

      private

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
                                                          access_token: input[:access_token]) # moonbear access token
        if responses.success?
          input[:origin_all_graphs] = responses.value!
          Success(input)
        else
          Failure(responses.failure)
        end
      end

      def self_comparison_text_score(input)
        redis = RedisCache.new(input[:config])
        responses = GetCustomizedScores.new
                                       .call(all_graphs: input[:origin_all_graphs],
                                             case_email: input[:email],
                                             redis: redis,
                                             user_key: input[:user_key])
        if responses.success?
          Success(responses.value!)
        else
          Failure(responses.failure)
        end
      end
    end
  end
end
