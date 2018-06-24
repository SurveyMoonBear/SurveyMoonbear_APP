# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class ItemOrm < Sequel::Model(:items)
      many_to_one :page,
                  class: :'SurveyMoonbear::Database::PageOrm'
    end
  end
end
