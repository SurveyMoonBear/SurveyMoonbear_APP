# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted survey
    # Usage: Service::DeleteSurvey.new.call(config: <config>, survey_id: "...")
    class DeleteSurvey
      include Dry::Transaction
      include Dry::Monads
      step :verify_ownership
      step :refresh_access_token
      step :remove_from_study
      step :delete_record_in_database
      step :delete_spreadsheet

      private

      def verify_ownership(input)
        survey = Repository::For[Entity::Survey].find_id(input[:survey_id])
        return Failure('Survey not found.') if survey.nil?
        account_data = input[:account] 
        account = Repository::Accounts.find_id(account_data['id'])
        role    = Repository::AccountSurveys.find_role(account.id, survey.id)
        policy = SurveysPolicy.new(account, survey, role)
        return Failure('You are not the owner of this survey.') unless policy.can_delete?

        input[:survey] = survey
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to verify ownership of the survey.')
      end

      # input { config:, survey_id: }
      def refresh_access_token(input)
        input[:access_token] = Google::Auth.new(input[:config]).refresh_access_token
        Success(input)
      rescue
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      def remove_from_study(input)
        study_id = Repository::For[Entity::Survey].find_id(input[:survey_id]).study_id
        unless study_id.nil?
          RemoveSurvey.new.call(config: input[:config], study_id: study_id, survey_id: input[:survey_id])
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to remove survey from study.')
      end

      # input { ..., access_token }
      def delete_record_in_database(input)
        input[:deleted_survey] = Repository::For[Entity::Survey].delete_from(input[:survey_id])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete record in database.')
      end

      # input { ..., deleted_survey: }
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
