# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class SurveyOrm < Sequel::Model(:surveys)
     many_to_many :owners,
                  left_class: :'SurveyMoonbear::Database::AccountOrm',
                  right_class: :'SurveyMoonbear::Database::SurveyOrm',
                  join_table: :accounts_surveys,
                  left_key: :owner_id,
                  right_key: :survey_id
                  
      one_to_many :account_surveys,
                  class: :'SurveyMoonbear::Database::AccountSurveysOrm'

      one_to_many :pages,
                  class: :'SurveyMoonbear::Database::PageOrm',
                  key: :survey_id,
                  order: :index

      one_to_many :launches,
                  class: :'SurveyMoonbear::Database::LaunchOrm',
                  key: :survey_id

      one_to_many :notifications,
                  class: :'SurveyMoonbear::Database::NotificationOrm'

      many_to_one :belongs_to_studies,
                  class: :'SurveyMoonbear::Database::StudyOrm'

      plugin :uuid, field: :id
      plugin :timestamps
    end
  end
end
