# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformSheetsSurveyToHTML.new.call(survey_id: "...", spreadsheet_id: "...", access_token: "...", random_seed: "...")
    class TransformSheetsSurveyToHTML
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_settings_from_database
      step :get_items_from_spreadsheet
      step :transform_survey_items_to_html

      private

      # input { survey_id:, spreadsheet_id:, access_token:, current_account: }
      def get_survey_settings_from_database(input)
        db_survey = GetSurveyFromDatabase.new.call(survey_id: input[:survey_id])
        if db_survey.success?
          input[:db_survey] = db_survey.value!
        else
          Failure(db_survey.failure)
        end

        input[:random_option] = JSON.parse(input[:db_survey].options)['random']
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get survey settings from database.')
      end

      # input { ..., random_option: }
      def get_items_from_spreadsheet(input)
        sheets_survey = GetSurveyFromSpreadsheet.new.call(spreadsheet_id: input[:spreadsheet_id],
                                                          access_token: input[:access_token],
                                                          owner: input[:current_account])
        if sheets_survey.success?
          input[:sheets_survey] = sheets_survey.value!
          Success(input)
        else
          Failure(sheets_survey.failure)
        end
      end

      # input { ..., sheets_survey: }
      def transform_survey_items_to_html(input)
        transform_result = TransformSurveyItemsToHTML.new.call(survey: input[:sheets_survey],
                                                               random_option: input[:random_option],
                                                               random_seed: input[:random_seed])

        if transform_result.success?
          Success(title: transform_result.value![:title],
                  pages: transform_result.value![:pages])
        else
          Failure(transform_result.failure)
        end
      end
    end
  end
end