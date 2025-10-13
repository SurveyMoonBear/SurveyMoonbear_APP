# frozen_string_literal: true

require 'dry/transaction'
require_relative '../../policies/survey_policy'

module SurveyMoonbear
  module Service
    # Service to add a codesigner to a survey
    # Usage: Service::AddCodesigner.new.call(account: {...}, survey_id: "...", codesigner_email: "...")
    class AddCodesigner
      include Dry::Transaction
      include Dry::Monads

      step :find_survey
      step :find_account
      step :authorize_add
      step :find_codesigner
      step :authorize_codesigner
      step :add_google_spreadsheet_editor
      step :add_codesigner

      private

      def find_survey(input)
        survey = Repository::Surveys.find_id(input[:survey_id])
        return Failure('Survey not found.') unless survey

        input[:survey] = survey
        Success(input)
      rescue StandardError => e
        Failure("Failed to find survey: #{e.message}")
      end

      def find_account(input)
        actor = Repository::Accounts.find_id(input[:account]['id'])
        return Failure('Account not found.') unless actor

        input[:actor] = actor
        Success(input)
      rescue StandardError => e
        Failure("Failed to find account: #{e.message}")
      end

      def authorize_add(input)
        role = Repository::Surveys.find_role(input[:actor].id, input[:survey].id)
        policy = SurveysPolicy.new(input[:actor], input[:survey], role)
        
        return Failure('You are not allowed to add codesigners to this survey.') unless policy.can_add_codesigners?

        Success(input)
      rescue StandardError => e
        Failure("Failed to authorize add operation: #{e.message}")
      end

      def find_codesigner(input)
        codesigner = Repository::Accounts.find_email(input[:codesigner_email])
        return Failure('Codesigner not found in system.') unless codesigner

        input[:codesigner] = codesigner
        Success(input)
      rescue StandardError => e
        Failure("Failed to find codesigner: #{e.message}")
      end

      def authorize_codesigner(input)
        role = Repository::Surveys.find_role(input[:codesigner].id, input[:survey].id)
        policy = SurveysPolicy.new(input[:codesigner], input[:survey], role)
        
        return Failure('This user cannot be added as codesigner.') unless policy.can_codesigner?

        Success(input)
      rescue StandardError => e
        Failure("Failed to authorize codesigner: #{e.message}")
      end

      def add_google_spreadsheet_editor(input)
        spreadsheet_id = input[:survey].origin_id
        access_token = input[:account]['access_token']
        codesigner_email = input[:codesigner].email

        GoogleSpreadsheet.new(access_token)
                         .add_editor(spreadsheet_id, codesigner_email)
        Success(input)
      rescue StandardError => e
        puts "ERROR in add_google_spreadsheet_editor: #{e.class} - #{e.message}"
        Failure("Failed to add editor: #{e.message}")
      end

      def add_codesigner(input)
        Repository::Surveys.add_codesigner(input[:codesigner].id, input[:survey_id])
        Success("#{input[:codesigner].username} was added as codesigner.")
      rescue Sequel::UniqueConstraintViolation
        Failure("#{input[:codesigner].username} is already a codesigner of this survey.")
      rescue StandardError => e
        Failure("Failed to add codesigner: #{e.message}")
      end
    end
  end
end
