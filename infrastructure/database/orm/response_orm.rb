# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class ResponseOrm < Sequel::Model(:responses)
      unrestrict_primary_key
      
      many_to_one :launch,
                  class: :'SurveyMoonbear::Database::LaunchOrm'
    end
  end
end
