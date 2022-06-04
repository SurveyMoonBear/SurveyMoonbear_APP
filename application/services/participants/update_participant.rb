# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted participant entity of new title
    # Usage: Service::UpdateParticipant.new.call(config: <config>, current_account: <current_account>, participant_id: "...", params: "...")
    class UpdateParticipant
      include Dry::Transaction
      include Dry::Monads

      step :check_email_changing
      step :update_participant

      private

      # input { config:, current_account, participant_id:, params: }
      def check_email_changing(input)
        participant = Repository::For[Entity::Participant].find_id(input[:participant_id])
        new_email = input[:params]['email'] if participant.study.enable_notification || participant.study.track_activity
        if !new_email.nil? && participant.email != new_email
          UpdateParticipantEmail.new.call(config: input[:config], current_account: input[:current_account],
                                          participant: participant, new_email: new_email)
        end
        Success(input)
      rescue
        Failure('Failed to update participant email')
      end

      # input { config:, current_account, participant_id:, params: }
      def update_participant(input)
        updated_participant = Repository::For[Entity::Participant].update(input[:participant_id], input[:params])
        Success(updated_participant)
      rescue
        Failure('Failed to update participant in database')
      end
    end
  end
end
