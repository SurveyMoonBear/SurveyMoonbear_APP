# frozen_string_literal: true

require 'dry/monads'
require_relative '../../policies/survey_policy'

module SurveyMoonbear
  module Service
    # Service to add a collaborator to a survey
    class AddCollaborator
      include Dry::Monads[:result]

      # Custom error for when a user is not allowed to add collaborators
      class ForbiddenError < StandardError
        def message = 'You are not allowed to add collaborators to this survey.'
      end

      # Custom error for when a collaborator is not found
      class NotFoundError < StandardError
        def message = 'Collaborator not found in system.'
      end

      def call(account:, survey_id:, collaborator_email:)
        survey       = find_survey!(survey_id)
        actor        = find_account!(account['id'])
        authorize_add!(actor, survey)

        collaborator = find_collaborator!(collaborator_email)
        authorize_collaborator!(collaborator, survey)

        add_collaborator!(collaborator, survey_id)
      rescue ForbiddenError, NotFoundError => e
        Failure(e.message)
      rescue StandardError
        Failure('Unexpected server error while adding collaborator.')
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

      def authorize_add!(account, survey)
        role   = Repository::AccountSurveys.find_role(account.id, survey.id)
        policy = SurveysPolicy.new(account, survey, role)
        raise ForbiddenError unless policy.can_add_codesigners?
      end

      def find_collaborator!(email)
        Repository::Accounts.find_email(email) ||
          (raise NotFoundError)
      end

      def authorize_collaborator!(collaborator, survey)
        role   = Repository::AccountSurveys.find_role(collaborator.id, survey.id)
        policy = SurveysPolicy.new(collaborator, survey, role)
        raise ForbiddenError unless policy.can_collaborate?
      end

      def add_collaborator!(collaborator, survey_id)
        relation = Entity::AccountSurvey.new(
          owner_id: collaborator.id,
          survey_id: survey_id,
          role: 'collaborator',
          created_at: Time.now,
          updated_at: Time.now
        )
        Repository::AccountSurveys.create(relation)
        Success("#{collaborator.username} was added as collaborator.")
      end
    end
  end
end
