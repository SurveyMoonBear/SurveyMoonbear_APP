# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateNotificationSession.new.call(config: <config>, notifications: [{...}], participants: [{...}])
    class CreateNotificationSession
      include Dry::Transaction
      include Dry::Monads

      step :create_notification_session

      private

      # input { config:, notifications:, participants: }
      def create_notification_session(input)
        input[:notifications].map do |notification|
          input[:participants].map do |participant|
            input_item = { config: input[:config], notification: notification, subscriber: participant.id }
            Messaging::NotificationScheduler.new(input_item).create_session
          end
        end
        Success(input)
      rescue
        Failure('Failed to create notification in session')
      end
    end
  end
end
