# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted participant entity of new title
    # Usage: Service::UpdateParticipant.new.call(participant_id: "...", params: "...")
    class UpdateParticipant
      include Dry::Transaction
      include Dry::Monads

      step :check_email_changing
      step :update_participant

      private

      # input { participant_id:, params: }
      def check_email_changing(input)
        participant = Repository::For[Entity::Participant].find_id(input[:participant_id])
        new_email = input[:params]['email']
        if !new_email.nil? && participant.study.enable_notification && participant.email != new_email
          # delete original arn:
          # 1. pending -> no need to delete and directly a new create
          # 2. confirmed
          if participant.noti_status == 'confirmed' || participant.noti_status == 'turn_off'
            Messaging::Notification.new(input[:config]).delete_subscription(participant.aws_arn)
          end
          # new create arn
          new_arn = Messaging::Notification.new(input[:config])
                                           .subscribe_topic(participant.study.aws_arn,
                                                            participant.contact_type,
                                                            new_email,
                                                            participant.id)
          input[:params]['aws_arn'] = new_arn
          input[:params]['noti_status'] = 'pending'
        end
        Success(input)
      rescue
        Failure('Failed to update participant aws arn')
      end

      # input { participant_id:, params: }
      def update_participant(input)
        updated_participant = Repository::For[Entity::Participant].update(input[:participant_id], input[:params])
        Success(updated_participant)
      rescue
        Failure('Failed to update participant title in database')
      end
    end
  end
end
