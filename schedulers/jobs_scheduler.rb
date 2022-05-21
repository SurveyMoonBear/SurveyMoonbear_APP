# frozen_string_literal: true

require 'figaro'
require 'aws-sdk-sns'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq/web'
require_relative '../init'

# Schedulers
module Schedulers
  # Scheduler config
  class App
    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment: ENV['RACK_ENV'] || 'development',
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config() = Figaro.env

    Sidekiq.configure_server do |config|
      config.on(:startup) do
        Sidekiq.schedule = YAML.load_file(File.expand_path('./schedulers/sidekiq_scheduler.yml'))
        SidekiqScheduler::Scheduler.instance.reload_schedule!
      end
    end
  end

  # Static job of update random notification's time
  class UpdateRandomNotification
    include Sidekiq::Worker

    def perform
      list = SurveyMoonbear::Repository::For[SurveyMoonbear::Entity::Notification].find_random
      return if list.empty?

      list.each do |notification|
        participants = SurveyMoonbear::Repository::For[SurveyMoonbear::Entity::Participant].find_study_confirmed(notification.study.id)
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
                     'class' => 'Schedulers::SendNotification',
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

    def perform(topic_arn, message, participant_id)
      SurveyMoonbear::Messaging::Notification.new(App.config)
                                             .send_notification(topic_arn,
                                                                message,
                                                                participant_id)
    end
  end
end
