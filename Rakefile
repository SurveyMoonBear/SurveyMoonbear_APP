# frozen_string_literal: true

require 'rake/testtask'

task :default do
  puts `rake -T`
end

desc 'run tests'
Rake::TestTask.new(:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
  t.warning = false
end

desc 'rerun tests'
task :respec do
  sh "rerun -c 'rake spec' --ignore 'coverage/*'"
end

namespace :run do
  task :dev do
    sh 'rerun -c "rackup -p 9090"'
  end

  task :test do
    sh 'RACK_ENV=test rerun -c "rackup -p 9000"'
  end
end

task :console do
  sh 'pry -r ./spec/test_load_all'
end

namespace :db do
  require_relative 'lib/init.rb'
  require_relative 'config/environments.rb' # load config info require 'sequel'
  require 'sequel' # TODO: remove after create orm

  Sequel.extension :migration
  app = SurveyMoonbear::App

  desc 'Run migrations'
  task :migrate do
    puts "Migrating #{app.environment} database to latest"
    Sequel::Migrator.run(app.DB, 'infrastructure/database/migrations')
  end

  desc 'Drop all tables'
  task :drop do
    require_relative 'config/environments.rb'
    # drop according to dependencies
    app.DB.drop_table :items
    app.DB.drop_table :pages
    app.DB.drop_table :responses
    app.DB.drop_table :launches
    app.DB.drop_table :surveys
    app.DB.drop_table :accounts
  end

  desc 'Reset all database tables'
  task reset: [:drop, :migrate]

  desc 'Delete dev or test database file'
  task :wipe do
    if app.environment == :production
      puts 'Cannot wipe production database!'
      return
    end

    FileUtils.rm(app.config.db_filename)
    puts "Deleted #{app.config.db_filename}"
  end
end

namespace :crypto do
  desc 'Create sample cryptographic key for database'
  task :db_key do
    puts "DB_KEY: #{SecureDB.generate_key}"
  end

  task :crypto_requires do
    require 'rbnacl/libsodium'
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
