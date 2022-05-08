# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted participant entity of new title
    # Usage: Service::UpdateParticipant.new.call(current_account: {...}, participant_id: "...", new_title: "...")
    class UpdateParticipant
      include Dry::Transaction
      include Dry::Monads

      step :update_participant

      private

      # input { ... }
      def update_participant(input)
        updated_participant = Repository::For[Entity::Participant].update(input[:participant_id], input[:params])
        Success(updated_participant)
      rescue
        Failure('Failed to update participant title in database')
      end
    end
  end
end
