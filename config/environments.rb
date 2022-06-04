require 'roda'
require 'figaro'
require 'sequel'
require 'rack/ssl-enforcer'
require 'rack/session/redis'
require 'rack/cache'
require 'redis-rack-cache'
require 'sidekiq'
require 'sidekiq-scheduler'

module SurveyMoonbear
  # Configuration for the API
  class App < Roda
    plugin :environments

    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment: environment,
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config() = Figaro.env

    configure do
      SecureDB.setup(config.DB_KEY)
      SecureSession.setup(config)
      SecureMessage.setup(config)
    end

    A_DAY = 60 * 60 * 24 # in seconds

    configure :development do
      # Allows running reload! in pry to restart entire app
      def self.reload!
        exec 'pry -r ./init.rb'
      end
    end

    configure :development, :test do
      ENV['DATABASE_URL'] = 'sqlite://' + config.DB_FILENAME

      use Rack::Session::Pool,
          expire_after: A_DAY
      use Rack::Cache,
          verbose: true,
          metastore: 'file:_cache/rack/meta',
          entitystore: 'file:_cache/rack/body'

      sidekiq_redis_configuration = {
        url: config.REDISCLOUD_SIDEKIQ_QUEUES_URL,
        ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
      }.freeze

      Sidekiq.configure_server do |s_config|
        s_config.redis = sidekiq_redis_configuration
        s_config.on(:startup) do
          Sidekiq.schedule = YAML.load_file(File.expand_path('./workers/sidekiq_scheduler.yml'))
          SidekiqScheduler::Scheduler.instance.reload_schedule!
        end
      end

      Sidekiq.configure_client do |s_config|
        s_config.redis = sidekiq_redis_configuration
      end
    end

    configure :production do
      use Rack::Session::Redis,
          expire_after: A_DAY, redis_server: App.config.REDIS_URL
      use Rack::Cache,
          verbose: true,
          metastore: config.REDIS_URL + config.REDIS_RACK_CACHE_METASTORE,
          entitystore: config.REDIS_URL + config.REDIS_RACK_CACHE_ENTITYTORE

      sidekiq_redis_configuration = {
        url: config.REDISCLOUD_SIDEKIQ_QUEUES_URL,
        ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
      }.freeze

      Sidekiq.configure_server do |s_config|
        s_config.redis = sidekiq_redis_configuration
        s_config.on(:startup) do
          Sidekiq.schedule = YAML.load_file(File.expand_path('./workers/sidekiq_scheduler.yml'))
          SidekiqScheduler::Scheduler.instance.reload_schedule!
        end
      end

      Sidekiq.configure_client do |s_config|
        s_config.redis = sidekiq_redis_configuration
      end
    end

    configure do
      DB = Sequel.connect(ENV['DATABASE_URL'])

      def self.DB
        DB
      end
    end
  end
end
