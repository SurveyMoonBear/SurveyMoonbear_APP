# frozen_string_literal: true

require 'dry/transaction'
require_relative '../../policies/survey_policy'
require_relative '../../../lib/google_spreadsheet'

module SurveyMoonbear
  module Service
    # Service to remove a codesigner from a survey
    # Usage: Service::RemoveCodesigner.new.call(account: {...}, survey_id: "...", codesigner_id: "...")
    class RemoveCodesigner
      include Dry::Transaction
      include Dry::Monads

      step :find_survey
      step :find_account
      step :authorize_remove
      step :find_codesigner
      step :remove_google_spreadsheet_editor
      step :remove_codesigner

      private

      # input { account:, survey_id:, codesigner_id: }
      def find_survey(input)
        survey = Repository::Surveys.find_id(input[:survey_id])
        return Failure('Survey not found.') unless survey

        input[:survey] = survey
        Success(input)
      rescue StandardError => e
        Failure("Failed to find survey: #{e.message}")
      end

      # input { ..., survey: }
      def find_account(input)
        actor = Repository::Accounts.find_id(input[:account]['id'])
        return Failure('Account not found.') unless actor

        input[:actor] = actor
        Success(input)
      rescue StandardError => e
        Failure("Failed to find account: #{e.message}")
      end

      # input { ..., actor:, survey: }
      def authorize_remove(input)
        role = Repository::Surveys.find_role(input[:actor].id, input[:survey].id)
        policy = SurveysPolicy.new(input[:actor], input[:survey], role)

        unless policy.can_remove_codesigner?
          return Failure('You are not allowed to remove codesigners from this survey.')
        end

        Success(input)
      rescue StandardError => e
        Failure("Failed to authorize remove operation: #{e.message}")
      end

      # input { ..., codesigner_id: }
      def find_codesigner(input)
        codesigner = Repository::Accounts.find_id(input[:codesigner_id])
        return Failure('Codesigner not found in system.') unless codesigner

        input[:codesigner] = codesigner
        Success(input)
      rescue StandardError => e
        Failure("Failed to find codesigner: #{e.message}")
      end

      # input { ..., codesigner:, survey: }
      def remove_google_spreadsheet_editor(input)
        spreadsheet_id = input[:survey].origin_id
        access_token = input[:account]['access_token']
        codesigner_email = input[:codesigner].email

        result = GoogleSpreadsheet.new(access_token)
                                  .remove_editor(spreadsheet_id, codesigner_email)

        if result[:status] == 'success'
          Success(input)
        elsif result[:status] == 'not_found'
          # Continue even if permission not found (maybe already removed)
          puts "WARNING: Permission for #{codesigner_email} not found in Google Spreadsheet"
          Success(input)
        else
          Failure("Failed to remove Google Spreadsheet editor: #{result[:body]}")
        end
      rescue StandardError => e
        puts "ERROR in remove_google_spreadsheet_editor: #{e.class} - #{e.message}"
        Failure("Failed to remove editor: #{e.message}")
      end

      # input { ..., codesigner:, survey_id: }
      def remove_codesigner(input)
        Repository::Surveys.remove_codesigner(input[:codesigner].id, input[:survey_id])
        Success("#{input[:codesigner].username} was removed as codesigner.")
      rescue StandardError => e
        Failure("Failed to remove codesigner: #{e.message}")
      end
    end
  end
end
