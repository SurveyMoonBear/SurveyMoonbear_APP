# frozen_string_literal: true
require_relative '../../init'
# To clean database during test runs
class DatabaseHelper
  def self.wipe_database
    SurveyMoonbear::App.DB.run('PRAGMA foreign_keys = OFF')
    SurveyMoonbear::Database::AccountOrm.map(&:destroy)
    SurveyMoonbear::Database::AccountSurveysOrm.map(&:destroy)
    SurveyMoonbear::Database::StudyOrm.map(&:destroy)
    SurveyMoonbear::Database::ParticipantOrm.map(&:destroy)
    SurveyMoonbear::Database::NotificationOrm.map(&:destroy)
    SurveyMoonbear::Database::SurveyOrm.map(&:destroy)
    SurveyMoonbear::Database::PageOrm.map(&:destroy)
    SurveyMoonbear::Database::ItemOrm.map(&:destroy)
    SurveyMoonbear::Database::LaunchOrm.map(&:destroy)
    SurveyMoonbear::Database::ResponseOrm.map(&:destroy)
    SurveyMoonbear::Database::VisualReportOrm.map(&:destroy)
    SurveyMoonbear::App.DB.run('PRAGMA foreign_keys = ON')
  end
end
