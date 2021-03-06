# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class PageOrm < Sequel::Model(:pages)
      many_to_one :survey,
                  class: :'SurveyMoonbear::Database::SurveyOrm'

      one_to_many :items,
                  class: :'SurveyMoonbear::Database::ItemOrm',
                  key: :page_id,
                  order: :order

      # plugin :uuid, field: :survey_id
    end
  end
end
