# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted notification
    # Usage: Service::DeleteNotification.new.call(config: <config>, notification_id: "...")
    class DeleteNotification
      include Dry::Transaction
      include Dry::Monads

      # step :delete_schedule
      step :delete_record_in_database

      private

      # # input { config:, notification_id: }
      # def delete_schedule(input)
      #   # Schedule: delete related schedule
      #   if enable_notification
      #     notification_list = notification.where(notification_id: input[:notification_id]).all
      #     notification_list.map { |notification| DeleteNotification.new.call(id: notification.id) }
      #   end
      #   Success(input)
      # rescue StandardError => e
      #   puts e
      #   Failure('Failed to delete schedule in database.')
      # end

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
