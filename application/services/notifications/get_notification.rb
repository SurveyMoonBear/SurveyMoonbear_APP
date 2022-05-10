# frozen_string_literal: true

require 'dry/transaction'
require 'json'
require 'cronex'
require 'time'

module SurveyMoonbear
  module Service
    # Return a deleted notification
    # Usage: Service::GetNotification.new.call(notification_id: "...")
    class GetNotification
      include Dry::Transaction
      include Dry::Monads

      step :get_notification
      step :get_notification_datetime

      private

      # input { notification_id: }
      def get_notification(input)
        input[:notification] = Repository::For[Entity::Notification].find_id(input[:notification_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get notification from database.')
      end

      # input { notification_id: , notification: }
      def get_notification_datetime(input)
        notification = input[:notification]
        input[:date_time] = case notification.type
                            when 'fixed'
                              notification.fixed_timestamp.getlocal.strftime('%Y-%m-%d %H:%M')
                              # local_running_sys(fixed_timestamp).getlocal.strftime('%Y-%m-%d %H:%M:%S')
                            when 'repeating'
                              case notification.repeat_at
                              when 'set_time'
                                Cronex::ExpressionDescriptor.new(notification.repeat_set_time).description
                              when 'random'
                                repeat = Cronex::ExpressionDescriptor.new("0 0 #{notification.repeat_random_every}").description
                                repeat = repeat.split('only').length > 1 ? repeat.split('only')[1] : 'on Everyday'
                                "random between #{notification.repeat_random_start} to #{notification.repeat_random_end}, #{repeat}"
                              end
                            end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to parse notification datetime.')
      end
    end
  end
end
