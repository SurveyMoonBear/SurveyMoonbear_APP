# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class SurveyOrm < Sequel::Model(:surveys)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'

      one_to_many :pages,
                  class: :'SurveyMoonbear::Database::PageOrm',
                  key: :survey_id,
                  order: :index

      one_to_many :launches,
                  class: :'SurveyMoonbear::Database::LaunchOrm',
                  key: :survey_id

      plugin :uuid, field: :id
      plugin :timestamps
    end
  end
end
