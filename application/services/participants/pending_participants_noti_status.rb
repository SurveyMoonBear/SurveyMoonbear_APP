# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::PendingParticipantsNotiStatus.new.call(config: <config>, study: {...}, participant: {...})
    class PendingParticipantsNotiStatus
      include Dry::Transaction
      include Dry::Monads

      step :get_participants_deleted_arn
      step :update_participants_deleted_arn_in_db
      step :delete_notification_session

      private

      # input { config:, study:, participant: }
      def get_participants_deleted_arn(input)
        input[:arn] = Messaging::NotificationSubscriber.new(input[:config])
                                             .subscribe_topic(input[:study].aws_arn,
                                                              input[:participant].contact_type,
                                                              input[:participant].email)
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to update participants deleted AWS arn.')
      end

      # input { config:, study:, participant:, arn: }
      def update_participants_deleted_arn_in_db(input)
        input[:participant] = Repository::For[Entity::Participant].update_arn(input[:participant].id,
                                                                              input[:arn], 'pending')
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to update participants deleted AWS arn.')
      end

      # input { config:, study:, participant:, arn: }
      def delete_notification_session(input)
        if input[:study].state == 'started'
          notifications = Repository::For[Entity::Notification].find_study(input[:study].id)
          DeleteNotificationSession.new.call(config: input[:config],
                                             notifications: notifications,
                                             participants: [input[:participant]])
        end
        Success(input[:participant])
      rescue StandardError => e
        puts e
        Failure('Failed to update participants deleted AWS arn.')
      end
    end
  end
end
