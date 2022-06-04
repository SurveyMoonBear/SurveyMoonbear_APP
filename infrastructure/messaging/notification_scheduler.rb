# frozen_string_literal: true

require 'sidekiq-scheduler'

module SurveyMoonbear
  module Messaging
    # Notification wrapper for AWS SNS
    class NotificationScheduler
      def initialize(input)
        @config = input[:config]
        @notification = input[:notification]
        @topic = @notification.study.aws_arn
        @subscriber = input[:subscriber]
        @message = "#{@notification.content} survey link: #{@config.APP_URL}/onlinesurvey/#{@notification.survey.id}/#{@notification.survey.launch_id}?p=#{@subscriber}"
      end

      def fixed_timestamp
        enabled = @notification.fixed_timestamp > Time.now.utc
        { 'at' => [@notification.fixed_timestamp],
          'class' => 'Worker::SendNotification',
          'enabled' => enabled,
          'queue' => 'study_notification_queue',
          'args' => [@topic, @message, @subscriber] }
      end

      def repeat_at_set_time
        { 'cron' => [@notification.repeat_set_time],
          'class' => 'Worker::SendNotification',
          'enabled' => true,
          'queue' => 'study_notification_queue',
          'args' => [@topic, @message, @subscriber] }
      end

      def repeat_at_random_time
        r_start = Time.parse(@notification.repeat_random_start) # "10:00"
        r_end = Time.parse(@notification.repeat_random_end) # "12:00"
        r_result = r_start + rand(r_end - r_start)
        { 'cron' => "#{r_result.min} #{r_result.hour} #{@notification.repeat_random_every}",
          'class' => 'Worker::SendNotification',
          'enabled' => true,
          'queue' => 'study_notification_queue',
          'args' => [@topic, @message, @subscriber] }
      end

      def create_hash
        if @notification.type == 'repeating' && @notification.repeat_at == 'set_time'
          repeat_at_set_time
        elsif @notification.type == 'repeating' && @notification.repeat_at == 'random'
          repeat_at_random_time
        else
          fixed_timestamp
        end
      end

      def create_session
        title = "#{@notification.title}_#{@notification.id}_#{@subscriber}"
        Sidekiq.set_schedule(title, create_hash)
      end

      def delete_session
        title = "#{@notification.title}_#{@notification.id}_#{@subscriber}"
        Sidekiq.remove_schedule(title)
      end
    end
  end
end
