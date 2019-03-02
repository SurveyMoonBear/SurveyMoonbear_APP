# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted survey entity of new title
    # Usage: Service::EditSurveyTitle.new.call(current_account: {...}, survey_id: "...", new_title: "...")
    class EditSurveyTitle
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_origin_id
      step :update_spreadsheet_title
      step :update_survey_title

      private

      # input { current_account:, survey_id:, new_title: }
      def get_survey_origin_id(input)
        survey = Repository::For[Entity::Survey].find_id(input[:survey_id])

        input[:origin_id] = survey.origin_id
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get survey origin id.')
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
      def update_survey_title(input)
        sheets_api = Google::Api::Sheets.new(input[:current_account]['access_token'])
        survey = Google::SurveyMapper.new(sheets_api)
                                     .load(input[:origin_id], input[:current_account])

        updated_survey = Repository::For[survey.class].update_title(survey)
        Success(updated_survey)
      rescue
        Failure('Failed to update survey title in database')
      end
    end
  end
end
