# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a updated survey
    # Usage: Service::StartSurvey.new.call(survey_id: "...", current_account: {...})
    class StartSurvey
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database
      step :get_survey_from_spreadsheet
      step :store_survey_into_database_and_launch

      private

      # input { survey_id:, current_account: }
      def get_survey_from_database(input)
        db_survey_res = GetSurveyFromDatabase.new.call(survey_id: input[:survey_id])

        if db_survey_res.success?
          input[:spreadsheet_id] = db_survey_res.value!.origin_id
          Success(input)
        else
          Failure(db_survey_res.failure)
        end
      end

      # input { ..., spreadsheet_id: }
      def get_survey_from_spreadsheet(input)
        new_survey_res = GetSurveyFromSpreadsheet.new.call(spreadsheet_id: input[:spreadsheet_id], 
                                                           access_token: input[:current_account]['access_token'],
                                                           owner: input[:current_account])
        if new_survey_res.success?
          input[:new_survey] = new_survey_res.value!
          Success(input)
        else
          Failure(new_survey_res.failure)
        end
      end

      # input { ..., new_survey: }
      def store_survey_into_database_and_launch(input)
        started_survey = Repository::For[ input[:new_survey].class ].add_launch(input[:new_survey])
        Success(started_survey)
      rescue StandardError => e
        puts e
        Failure('Failed to store the new survey into database and launch.')
      end
    end
  end
end
