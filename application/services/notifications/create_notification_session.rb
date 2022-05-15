# frozen_string_literal: true

require 'dry/transaction'
require 'sidekiq-scheduler'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateNotificationSession.new.call(notification: {...}, study: {...},
    #                                                    survey_link: {...}, participant_id: {...})
    class CreateNotificationSession
      include Dry::Transaction
      include Dry::Monads

      step :filter_notification_type
      step :create_notification_session

      private

      def fixed_timestamp(notification, study, message, participant_id)
        enabled = notification.fixed_timestamp > Time.now.utc
        { 'at' => [notification.fixed_timestamp],
          'class' => 'Jobs::SendNotification',
          'enabled' => enabled,
          'args' => [study.aws_arn, message, participant_id] }
      end

      def repeat_at_set_time(notification, study, message, participant_id)
        { 'cron' => [notification.repeat_set_time],
          'class' => 'Jobs::SendNotification',
          'enabled' => true,
          'args' => [study.aws_arn, message, participant_id] }
      end

      def repeat_at_random_time(notification, study, message, participant_id)
        r_start = Time.parse(notification.repeat_random_start) # "10:00"
        r_end = Time.parse(notification.repeat_random_end) # "12:00"
        r_result = r_start + rand(r_end - r_start)
        { 'cron' => "#{r_result.min} #{r_result.hour} #{notification.repeat_random_every}",
          'class' => 'Jobs::SendNotification',
          'enabled' => true,
          'args' => [study.aws_arn, message, participant_id] }
      end

      # input { notification:, study:, survey_link:, participant_id: }
      def filter_notification_type(input)
        notification = input[:notification]
        study = input[:study]
        message = "#{notification.content} survey link: #{input[:survey_link]}"
        input[:hash] = if notification.type == 'repeating' && notification.repeat_at == 'set_time'
                         repeat_at_set_time(notification, study, message, input[:participant_id])
                       elsif notification.type == 'repeating' && notification.repeat_at == 'random'
                         repeat_at_random_time(notification, study, message, input[:participant_id])
                       else
                         fixed_timestamp(notification, study, message, input[:participant_id])
                       end
        Success(input)
      rescue
        Failure('Failed to create notification hash')
      end

      # input { notification:, study:, survey_link:, participant_id:, hash: }
      def create_notification_session(input)
        title = "#{input[:notification].title}_#{input[:notification].id}_#{input[:participant_id]}"
        Sidekiq.set_schedule(title, input[:hash])
        Success(input[:notification])
      rescue
        Failure('Failed to create notification in session')
      end
    end
  end
end
