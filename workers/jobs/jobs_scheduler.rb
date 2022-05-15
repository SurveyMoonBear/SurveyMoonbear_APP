# frozen_string_literal: true

require 'figaro'
require 'aws-sdk-sns'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq/web'
# require_relative '../require_app'

# Jobs
module Jobs
  # Testing sidekiq
  class WorkWell
    include Sidekiq::Worker

    def perform
      puts 'work well'
    end
  end

  # Job config
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
        Sidekiq.schedule = YAML.load_file(File.expand_path('./workers/jobs/sidekiq_scheduler.yml'))
        SidekiqScheduler::Scheduler.instance.reload_schedule!
      end
    end
  end

  # Static job of update random notification's time
  class UpdateRandomNotification
    include Sidekiq::Worker
    # require_app

    def perform
      list = SurveyMoonbear::Database::NotificationOrm.where(repeat_at: 'random').all
      return if list.empty?

      list.each do |notification|
        title = "#{notification.title}_#{notification.id}"
        schedule = Sidekiq.get_schedule(title)

        next if schedule.nil?

        r_start = Time.parse(notification.repeat_random_start) # "10:00"
        r_end = Time.parse(notification.repeat_random_end) # "12:00"
        r_result = r_start + rand(r_end - r_start)
        Sidekiq.set_schedule(
          title, { 'cron' => "#{r_result.min} #{r_result.hour} #{notification.repeat_random_every}",
                   'class' => 'Jobs::SendNotification',
                   'enabled' => schedule['enabled'],
                   'args' => schedule['args'] }
        )
      end
    end
  end

  # Job of sending a notification through aws sns
  class SendNotification
    include Sidekiq::Worker

    def perform(topic_arn, message)
      puts 'Message sending.'

      sns_client = Aws::SNS::Client.new(
        access_key_id: App.config.AWS_ACCESS_KEY_ID,
        secret_access_key: App.config.AWS_SECRET_ACCESS_KEY,
        region: App.config.AWS_REGION
      )

      sns_client.publish(topic_arn: topic_arn, message: message)

      puts "The message: #{message} was sent."
    end
  end
end
