# frozen_string_literal: true

require 'figaro'
require 'aws-sdk-sns'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq/web'
require_relative '../init'

# Scheduler
module Scheduler
  # Static job of update random notification's time
  class UpdateRandomNotification
    include Sidekiq::Worker
    include SurveyMoonbear

    def perform
      list = Repository::For[Entity::Notification].find_random
      return if list.empty?

      list.each do |notification|
        participants = Repository::For[Entity::Participant].find_study_confirmed(notification.study.id)
        next if participants.empty?

        participants.map do |participant|
          title = "#{notification.title}_#{notification.id}_#{participant.id}"
          schedule = Sidekiq.get_schedule(title)

          next if schedule.nil?

          r_start = Time.parse(notification.repeat_random_start) # "10:00"
          r_end = Time.parse(notification.repeat_random_end) # "12:00"
          r_result = r_start + rand(r_end - r_start)
          Sidekiq.set_schedule(
            title, { 'cron' => "#{r_result.min} #{r_result.hour} #{notification.repeat_random_every}",
                     'class' => 'Scheduler::SendNotification',
                     'enabled' => schedule['enabled'],
                     'args' => schedule['args'] }
          )
        end
      end
    end
  end

  # Job of sending a notification through aws sns
  class SendNotification
    include Sidekiq::Worker
    include SurveyMoonbear

    def perform(topic_arn, message, participant_id)
      Messaging::NotificationSubscriber.new(App.config)
                                       .send_email_notification(topic_arn, message, participant_id)
    end
  end
end
