# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class StudyOrm < Sequel::Model(:studies)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'

      plugin :uuid, field: :id
      plugin :timestamps
    end
  end
end
