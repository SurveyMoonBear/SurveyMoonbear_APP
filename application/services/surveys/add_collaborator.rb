# frozen_string_literal: true

require 'dry/monads'

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
        survey = Repository::For[Entity::Survey].find_id(survey_id)
        raise NotFoundError unless survey

        unless survey.owner.id == account['id']
          raise ForbiddenError
        end

        collaborator = Repository::For[Entity::Account].find_email(collaborator_email)
        raise NotFoundError unless collaborator

        existing = Repository::For[Entity::AccountSurvey]
                     .find(owner_id: collaborator.id, survey_id: survey_id)
        return Failure('Already a collaborator') if existing

        new_relation = Entity::AccountSurvey.new(
          owner_id: collaborator.id,
          survey_id: survey_id,
          role: 'collaborator',
          created_at: Time.now,
          updated_at: Time.now
        )

        Repository::For[Entity::AccountSurvey].create(new_relation)

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
