# frozen_string_literal: true

require 'dry/transaction'
require 'json'
require 'cronex'
require 'time'

module SurveyMoonbear
  module Service
    # Return a deleted notification
    # Usage: Service::GetNotifications.new.call(study_id: "...")
    class GetNotifications
      include Dry::Transaction
      include Dry::Monads

      step :get_notification_list

      private

      # input { study_id: }
      def get_notification_list(input)
        notification_list = Repository::For[Entity::Notification].find_study(input[:study_id])
        notification_list.map! do |notification|
          notification = GetNotification.new.call(notification_id: notification.id)
          notification.value! if notification.success?
        end
        Success(notification_list)
      rescue StandardError => e
        puts e
        Failure('Failed to get notification list from database.')
      end
    end
  end
end
