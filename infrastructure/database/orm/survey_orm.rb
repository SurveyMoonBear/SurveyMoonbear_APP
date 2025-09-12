# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class SurveyOrm < Sequel::Model(:surveys)
     many_to_many :codesigners,
                  join_table: :accounts_surveys,
                  left_key: :survey_id,
                  right_key: :codesigner_id
     many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm',
                  key: :owner_id
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

      def designers
        [owner] + codesigners.all
      end
    end
  end
end
