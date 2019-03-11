# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::CopySurvey.new.call(config: <config>, current_account: {}, spreadsheet_id: "", title: "")
    class CopySurvey
      include Dry::Transaction
      include Dry::Monads

      step :refresh_access_token
      step :create_spreadsheet
      step :add_editor
      step :set_survey_title
      step :store_into_database

      private

      # input { config:, current_account:, spreadsheet_id:, title: }
      def refresh_access_token(input)
        input[:current_account]['access_token'] = Google::Auth.new(input[:config]).refresh_access_token

        Success(input)
      rescue
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      # input { ... }
      def create_spreadsheet(input)
        response = Google::Api::Drive.new(input[:current_account]['access_token'])
                                     .copy_drive_file(input[:spreadsheet_id])
        input[:new_spreadsheet_id] = response['id']

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to copy spreadsheet file.')
      end

      # input { ..., new_spreadsheet_id: }
      def add_editor(input)
        sleep(1)
        GoogleSpreadsheet.new(input[:current_account]['access_token'])
                         .add_editor(input[:new_spreadsheet_id], input[:current_account]['email'])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to add editor.')
      end

      # input { ... }
      def set_survey_title(input)
        unless input[:title].nil? || input[:title].empty?
          Google::Api::Sheets.new(input[:current_account]['access_token'])
                            .update_gs_title(input[:new_spreadsheet_id], input[:title])
        end

        Success(input)
      rescue
        Failure('Failed to set survey title.')
      end

      # input { ... }
      def store_into_database(input)
        sheets_api = Google::Api::Sheets.new(input[:current_account]['access_token'])
        new_survey = Google::SurveyMapper.new(sheets_api)
                                         .load(input[:new_spreadsheet_id], input[:current_account])
        survey = Repository::For[new_survey.class].find_or_create(new_survey)
        Success(survey)
      rescue
        Failure('Failed to store the new survey into database.')
      end
    end
  end
end