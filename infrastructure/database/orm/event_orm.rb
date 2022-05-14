# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Event Entities
    class EventOrm < Sequel::Model(:events)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'

      many_to_one :participant,
                  class: :'SurveyMoonbear::Database::ParticipantOrm'

      plugin :timestamps
    end
  end
end
