# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateParticipant.new.call(config: <config>, study_id: {...})
    class ConfirmParticipantsStatus
      include Dry::Transaction
      include Dry::Monads

      step :get_study_arn_from_db
      step :get_updated_participants_arn
      step :update_participants_arn_in_db

      private

      # input { config:, study_id:}
      def get_study_arn_from_db(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get study arn from database.')
      end

      # input { config:, study_id:, study: }
      def get_updated_participants_arn(input)
        input[:updated_sub_arn] = Messaging::Notification.new(input[:config])
                                                         .confirm_subscriptions(input[:study].aws_arn)
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get updated participant arn.')
      end

      # input { config:, study_id:, study:, }
      def update_participants_arn_in_db(input)
        participants = Repository::For[Entity::Participant].find_study(input[:study].id)
        participants.each do |participant|
          next unless participant.status == 'pending'

          # TODO: sms contact type
          sub_arn = input[:updated_sub_arn][participant.email]
          params = { "aws_arn": sub_arn, "status": 'confirmed' } unless sub_arn.nil?
          UpdateParticipant.new.call(participant_id: participant.id, params: params)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to update participants AWS arn.')
      end
    end
  end
end
