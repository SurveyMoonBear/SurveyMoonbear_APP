# frozen_string_literal: true

require 'rake/testtask'

task :default do
  puts `rake -T`
end

desc 'run all tests'
Rake::TestTask.new("spec:all") do |t|
  t.pattern = 'spec/*_spec.rb'
  t.warning = false
end

desc 'run tests exclude no-cassettes ones'
Rake::TestTask.new(:spec) do |t|
  t.test_files = FileList['spec/*_spec.rb'].exclude('spec/*_novcr_spec.rb')
  t.warning = false
end

desc 'run no-cassetttes tests'
Rake::TestTask.new("spec:novcr") do |t|
  t.pattern = 'spec/*_novcr_spec.rb'
  t.warning = false
end

desc 'rerun tests'
task :respec do
  sh "rerun -c 'rake spec' --ignore 'coverage/*'"
end

namespace :run do
  task :dev do
    sh 'rerun -c "heroku local -f Procfile.dev -p 9090"'
    sh 'rerun -c "rackup -p 9090"'
    # sh 'rackup -p 9090'
  end

  task :test do
    sh 'RACK_ENV=test rerun -c "heroku local -f Procfile.test -p 9090"'
  end
end

namespace :queues do
  task :config do
    require 'aws-sdk-sqs'
    require_relative 'config/environments.rb'
    @app = SurveyMoonbear::App

    @sqs = Aws::SQS::Client.new(
      access_key_id: @app.config.AWS_ACCESS_KEY_ID,
      secret_access_key: @app.config.AWS_SECRET_ACCESS_KEY,
      region: @app.config.AWS_REGION
    )
  end

  desc 'Create SQS queue for Shoryuken'
  task :create => :config do
    puts "Environment: #{@app.environment}"
    @sqs.create_queue(queue_name: @app.config.RES_QUEUE_NAME)

    puts 'Queue created:'
    puts "  Name: #{@app.config.RES_QUEUE_NAME}"
    puts "  Region: #{@app.config.AWS_REGION}"
    puts "  URL: #{@app.config.RES_QUEUE_URL}"
  rescue StandardError => error
    puts "Error creating queue: #{error}"
  end
end

# Make sure the queue of current env has been created before run the worker
namespace :worker do
  namespace :run do
    desc 'Run the background response-store worker in development mode'
    task :dev do
      sh 'RACK_ENV=development bundle exec shoryuken -r ./workers/responses_store_worker.rb -C ./workers/shoryuken_dev.yml'
    end

    desc 'Run the background response-store worker in test mode'
    task :test do
      sh 'RACK_ENV=test bundle exec shoryuken -r ./workers/responses_store_worker.rb -C ./workers/shoryuken_test.yml'
    end

    desc 'Run the background response-store worker in production mode'
    task :production do
      sh 'RACK_ENV=production bundle exec shoryuken -r ./workers/responses_store_worker.rb -C ./workers/shoryuken.yml'
    end
  end
end

task :console do
  sh 'pry -r ./init.rb'
end

namespace :vcr do
  desc 'Delete cassette fixtures'
  task :delete do
    sh 'rm spec/fixtures/cassettes/*.yml' do |ok, _|
      puts (ok ? 'Cassettes deleted' : 'No cassettes found')
    end
  end
end

namespace :db do
  require_relative 'lib/init.rb'
  require_relative 'config/environments.rb' # load config info require 'sequel'
  require 'sequel' # TODO: remove after create orm
  app = SurveyMoonbear::App

  desc 'Run migrations'
  task :migrate do
    Sequel.extension :migration
    puts "Migrating #{app.environment} database to latest"
    Sequel::Migrator.run(app.DB, 'infrastructure/database/migrations')
  end

  desc 'Wipe records from all tables'
  task :wipe do
    require_relative 'spec/helpers/database_helper.rb'
    DatabaseHelper.setup_database_cleaner
    DatabaseHelper.wipe_database
    puts "Wiped all records from tables in #{app.environment} database"
  end

  desc 'Delete dev or test database file'
  task :drop do
    if app.environment == :production
      puts 'Cannot remove production database!'
      return
    end

    FileUtils.rm(app.config.DB_FILENAME)
    puts "Deleted #{app.config.DB_FILENAME}"
  end

  # desc 'Reset all database tables'
  # task reset: [:drop, :migrate]
end

namespace :crypto do
  desc 'Create sample cryptographic key for database'
  task :db_key do
    puts "DB_KEY: #{SecureDB.generate_key}"
  end

  task :crypto_requires do
    require 'rbnacl'
    require 'base64'
  end

  desc 'Create rbnacl key'
  task msg_key: [:crypto_requires] do
    puts "New MSG_KEY: #{SecureMessage.generate_key}"
  end

  desc 'Create cookie secret'
  task session_secret: [:crypto_requires] do
    puts "New session secret (base64 encoded): #{SecureSession.generate_secret}"
  end
end

namespace :session do
  desc 'Wipe all sessions stored in Redis'
  task :wipe => :load_all do
    require 'redis'
    puts 'Deleting all sessions from Redis session store'
    wiped = SessionSecure.wipe_radis_session
    puts "#{wiped.count} sessions deleted"
  end
end
