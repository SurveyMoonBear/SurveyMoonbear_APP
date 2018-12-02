# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted survey
    # Usage: Service::DeleteSurvey.new.call(config: <config>, survey_id: "...")
    class DeleteSurvey
      include Dry::Transaction
      include Dry::Monads

      step :refresh_access_token
      step :delete_record_in_database
      step :delete_spreadsheet

      private

      # input {config:, survey_id:}
      def refresh_access_token(input)
        input[:access_token] = Google::Auth.new(input[:config]).refresh_access_token
        Success(input)
      rescue
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      # input {config:, survey_id:, access_token}
      def delete_record_in_database(input)
        input[:deleted_survey] = Repository::For[Entity::Survey].delete_from(input[:survey_id])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete record in database.')
      end

      # input {config:, survey_id:, access_token:, deleted_survey:}
      def delete_spreadsheet(input)
        GoogleSpreadsheet.new(input[:access_token])
                         .delete_spreadsheet(input[:deleted_survey].origin_id)
        Success(input[:deleted_survey])
      rescue StandardError => e
        puts e
        Failure('Failed to delete spreadsheet.')
      end
    end
  end
end
