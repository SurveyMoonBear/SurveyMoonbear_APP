require 'roda'
require 'econfig'
require 'rack/ssl-enforcer'
require 'rack/session/redis'

module SurveyMoonbear
  # Configuration for the API
  class App < Roda
    plugin :environments

    extend Econfig::Shortcut
    Econfig.env = environment.to_s
    Econfig.root = '.'

    configure do
      SecureDB.setup(config.DB_KEY)
      SecureSession.setup(config)
      SecureMessage.setup(config)
    end

    THIRTY_MINUTES = 60 * 60 # in seconds

    configure :development do
      # Allows running reload! in pry to restart entire app
      def self.reload!
        exec 'pry -r ./spec/test_load_all'
      end
    end

    configure :development, :test do
      ENV['DATABASE_URL'] = 'sqlite://' + config.db_filename

      use Rack::Session::Pool,
          expire_after: THIRTY_MINUTES
    end

    configure :production do
      use Rack::Session::Redis,
          expire_after: THIRTY_MINUTES, redis_server: App.config.REDIS_URL
    end

    configure do
      require 'sequel'
      DB = Sequel.connect(ENV['DATABASE_URL'])

      def self.DB
        DB
      end
    end
  end
end
