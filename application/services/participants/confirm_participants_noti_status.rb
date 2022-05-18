# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateParticipant.new.call(config: <config>, study_id: {...})
    class ConfirmParticipantsNotiStatus
      include Dry::Transaction
      include Dry::Monads

      step :get_study_arn_from_db
      step :create_uuids
      step :get_updated_participants_arn
      step :get_original_participants
      step :update_participants_arn_in_db
      step :create_notification_session

      private

      # input { config:, study_id:}
      def get_study_arn_from_db(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get study arn from database.')
      end

      def create_uuids(input)
        participants = Repository::For[Entity::Participant].find_study(input[:study].id)
        input[:uuids] = {}
        participants.map do |participant|
          input[:uuids].update({ participant.email => participant.id })
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to create uuid hash.')
      end

      # input { config:, study_id:, study: }
      def get_updated_participants_arn(input)
        input[:upd_arn] = Messaging::Notification.new(input[:config])
                                                 .confirm_subscriptions(input[:study].aws_arn, input[:uuids])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get updated participant arn.')
      end

      # input { config:, study_id:, study:, upd_arn: }
      def get_original_participants(input)
        input[:participants] = Repository::For[Entity::Participant].find_study(input[:study].id)
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to update participants AWS arn.')
      end

      # input { config:, study_id:, study:, upd_arn:, participants: }
      def update_participants_arn_in_db(input)
        input[:participants].each do |participant|
          sub_arn = input[:upd_arn][participant.email]
          next unless participant.noti_status == 'pending' && !sub_arn.nil?

          Repository::For[Entity::Participant].update_arn(participant.id, sub_arn, 'confirmed')
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to update participants AWS arn.')
      end

      # input { config:, study_id:, study:, upd_arn:, participants: }
      def create_notification_session(input)
        if input[:study].state == 'started'
          StartNotification.new.call(config: input[:config], study_id: input[:study_id])
        end
        Success(input)
      rescue
        Failure('Failed to create notification session')
      end
    end
  end
end
