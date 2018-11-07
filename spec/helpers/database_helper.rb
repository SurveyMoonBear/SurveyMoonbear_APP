# frozen_string_literal: true

require 'database_cleaner'

# To clean database during test runs
class DatabaseHelper
  def self.setup_database_cleaner
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
  end

  def self.wipe_database
    SurveyMoonbear::App.DB.run('PRAGMA foreign_keys = OFF')
    DatabaseCleaner.clean
    SurveyMoonbear::App.DB.run('PRAGMA foreign_keys = ON')
  end
end