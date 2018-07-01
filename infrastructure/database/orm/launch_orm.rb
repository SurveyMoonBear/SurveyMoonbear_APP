# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class LaunchOrm < Sequel::Model(:launches)
      many_to_one :survey,
                  class: :'SurveyMoonbear::Database::SurveyOrm'

      one_to_many :responses,
                  class: :'SurveyMoonbear::Database::ResponseOrm',
                  key: :launch_id

      plugin :timestamps, create: :started_at
      plugin :uuid, field: :id
    end
  end
end
