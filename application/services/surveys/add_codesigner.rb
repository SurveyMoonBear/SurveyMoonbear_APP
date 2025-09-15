# frozen_string_literal: true

require 'dry/monads'
require_relative '../../policies/survey_policy'

module SurveyMoonbear
  module Service
    # Service to add a codesigner to a survey
    class AddCodesigner
      include Dry::Monads[:result]

      # Custom error for when a user is not allowed to add codesigners
      class ForbiddenError < StandardError
        def message = 'You are not allowed to add codesigners to this survey.'
      end

      # Custom error for when a codesigner is not found
      class NotFoundError < StandardError
        def message = 'Codesigner not found in system.'
      end

      def call(account:, survey_id:, codesigner_email:)
        survey       = find_survey!(survey_id)
        actor        = find_account!(account['id'])
        authorize_add!(actor, survey)

        codesigner = find_codesigner!(codesigner_email)
        authorize_colldesigner!(codesigner, survey)
        add_codesigner!(codesigner, survey_id)
      rescue ForbiddenError, NotFoundError => e
        Failure(e.message)
      rescue StandardError
        Failure('Unexpected server error while adding codesigner.')
      end

      private

      def find_survey!(survey_id)
        Repository::Surveys.find_id(survey_id) ||
          (raise NotFoundError)
      end

      def find_account!(account_id)
        Repository::Accounts.find_id(account_id) ||
          (raise NotFoundError)
      end

      def authorize_add!(actor, survey)
        role = Repository::Surveys.find_role(actor.id, survey.id)
        policy = SurveysPolicy.new(actor, survey, role)
        raise ForbiddenError unless policy.can_add_codesigners?
      end

      def find_codesigner!(email)
        Repository::Accounts.find_email(email) ||
          (raise NotFoundError)
      end

      def authorize_colldesigner!(codesigner, survey)
        role = Repository::Surveys.find_role(codesigner.id, survey.id)
        policy = SurveysPolicy.new(codesigner, survey, role)
        raise ForbiddenError unless policy.can_codesigner?
      end

      def add_codesigner!(codesigner, survey_id)
        Repository::Surveys.add_codesigner(codesigner.id, survey_id)
        Success("#{codesigner.username} was added as codesigner.")
        rescue Sequel::UniqueConstraintViolation
          Failure("#{codesigner.username} is already a codesigner of this survey.")
        rescue StandardError => e
          Failure("Failed to add codesigner: #{e.message}")
      end
    end
  end
end
