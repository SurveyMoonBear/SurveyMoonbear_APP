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
    end
  end

  # Polling messages from AWS SQS
  class PollingMessages
    include Sidekiq::Worker
    include SurveyMoonbear

    def perform
      Messaging::Queue.new(App.config.RES_QUEUE_URL, App.config).poll do |msg|
        puts "Processing SQS MessageId: #{msg.message_id}"
        Worker::StoreResponses.perform_async(msg.message_id, msg.body) if msg
      end
    rescue StandardError => e
      puts 'Errors on receiving message from SQS'
      puts e
      raise
    end
  end

  # Storing responses from AWS SQS message
  class StoreResponses
    include Sidekiq::Worker
    include SurveyMoonbear

    def perform(msg_id, msg_body)
      response_hashes = JSON.parse(msg_body)
      store_responses(response_hashes)
      puts "SQS MessageId: #{msg_id} is completed"
    rescue StandardError => e
      puts "Errors on SQS MessageId: #{msg_id}"
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
