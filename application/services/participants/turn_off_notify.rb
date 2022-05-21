# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted participant entity of new title
    # Usage: Service::TurnOffNotify.new.call(config: <config>, participant_id: "...")
    class TurnOffNotify
      include Dry::Transaction
      include Dry::Monads

      step :delete_notification_session
      step :update_notify_status_in_database

      private

      # input { config:, participant_id: }
      def delete_notification_session(input)
        participant = Repository::For[Entity::Participant].find_id(input[:participant_id])
        if participant.study.state == 'started'
          notifications = Repository::For[Entity::Notification].find_study(participant.study.id)
          DeleteNotificationSession.new.call(config: input[:config], notifications: notifications, participants: [participant])
        end
        Success(input)
      rescue
        Failure('Failed to delete notification from session')
      end

      # input { config:, participant_id: }
      def update_notify_status_in_database(input)
        participant = Repository::For[Entity::Participant].update_noti_status(input[:participant_id], 'turn_off')
        Success(participant)
      rescue
        Failure('Failed to update participant notify status in db.')
      end
    end
  end
end
