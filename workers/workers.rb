# frozen_string_literal: true

require 'figaro'
require 'aws-sdk-sns'
require 'aws-sdk-sqs'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq/web'
require_relative '../init'

# Worker
module Worker
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
                     'class' => 'Worker::SendNotification',
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
    rescue StandardError => e
      puts 'Errors on sending notification'
      puts e
      raise
    end
  end

  # Usage: Worker::StoreResponses.perform_async(response_hashes)
  # Storing survey responses
  class StoreResponses
    include Sidekiq::Job
    include SurveyMoonbear

    def perform(response_hashes)
      store_responses(response_hashes)
      puts 'Storing survey response is completed'
    rescue StandardError => e
      puts 'Errors on storing survey response'
      puts e
      raise
    end

    private

    def store_responses(response_hashes)
      if ENV['RACK_ENV'] == 'production'
        App.DB[:responses].multi_insert(response_hashes)
      else # For SQLite
        App.DB.run('PRAGMA foreign_keys = OFF')
        App.DB[:responses].multi_insert(response_hashes)
        App.DB.run('PRAGMA foreign_keys = ON')
      end
    end
  end
end
