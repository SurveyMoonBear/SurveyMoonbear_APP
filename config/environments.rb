require 'roda'
require 'figaro'
require 'sequel'
require 'rack/ssl-enforcer'
require 'rack/session/redis'
require 'rack/cache'
require 'redis-rack-cache'

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
    end

    configure :production do
      use Rack::Session::Redis,
          expire_after: A_DAY, redis_server: App.config.REDIS_URL
      use Rack::Cache,
          verbose: true,
          metastore: config.REDIS_URL + '/0/metastore',
          entitystore: config.REDIS_URL + '/0/entitystore'
    end

    configure do
      DB = Sequel.connect(ENV['DATABASE_URL'])

      def self.DB
        DB
      end
    end
  end
end
