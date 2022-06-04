# frozen_string_literal: true

require 'dry/transaction'
require 'sidekiq-scheduler'

module SurveyMoonbear
  module Service
    # Return a deleted notification
    # Usage: Service::DeleteNotification.new.call(config: <config>, notification_id: "...")
    class DeleteNotification
      include Dry::Transaction
      include Dry::Monads

      step :delete_notification_session
      step :delete_record_in_database

      private

      # input { config:, notification_id: }
      def delete_notification_session(input)
        notification = Repository::For[Entity::Notification].find_id(input[:notification_id])

        if notification.study.state == 'started'
          participants = Repository::For[Entity::Participant].find_study_confirmed(notification.study.id)
          DeleteNotificationSession.new.call(config: input[:config],
                                             notifications: [notification],
                                             participants: participants)
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete schedule from session.')
      end

      # input { config:, notification_id: }
      def delete_record_in_database(input)
        input[:deleted_notification] = Repository::For[Entity::Notification].delete_from(input[:notification_id])
        Success(input[:deleted_notification])
      rescue StandardError => e
        puts e
        Failure('Failed to delete record in database.')
      end
    end
  end
end
