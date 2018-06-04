# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class ResponseOrm < Sequel::Model(:responses)
      many_to_one :survey,
                  class: :'SurveyMoonbear::Database::SurveyOrm'
    end
  end
end
