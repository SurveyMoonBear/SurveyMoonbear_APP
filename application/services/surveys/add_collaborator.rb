# frozen_string_literal: true

require 'dry/monads'
require_relative '../../policies/survey_policy'


module SurveyMoonbear
  module Service
    class AddCollaborator
      include Dry::Monads[:result]

      class ForbiddenError < StandardError
        def message = 'You are not allowed to add collaborators to this survey.'
      end

      class NotFoundError < StandardError
        def message = 'Collaborator not found in system.'
      end

      def call(account:, survey_id:, collaborator_email:)
        
        raise NotFoundError unless survey = Repository::Surveys.find_id(survey_id)
        account = Repository::Accounts.find_id(account['id'])
        role    = Repository::AccountSurveys.find_role(account.id, survey.id)
        policy = SurveysPolicy.new(account, survey, role)

        raise ForbiddenError unless policy.can_add_collaborators?

        collaborator = Repository::Accounts.find_email(collaborator_email)
        raise NotFoundError unless collaborator

        collaborator_role = Repository::AccountSurveys.find_role(collaborator.id, survey_id)

        policy_for_collaborator = SurveysPolicy.new(collaborator, survey, collaborator_role)
        return Failure('Already a collaborator')  unless  policy_for_collaborator.can_collaborate?

        new_relation = Entity::AccountSurvey.new(
          owner_id: collaborator.id,
          survey_id: survey_id,
          role: 'collaborator',
          created_at: Time.now,
          updated_at: Time.now
        )

        Repository::AccountSurveys.create(new_relation)

        Success("#{collaborator.username} was added as collaborator.")
      rescue ForbiddenError, NotFoundError => e
        Failure(e.message)
      rescue StandardError => e
        puts "AddCollaborator Error: #{e.inspect}"
        Failure('Unexpected server error while adding collaborator.')
      end
    end
  end
end
