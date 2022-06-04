# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Participant Entities
    class ParticipantOrm < Sequel::Model(:participants)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'

      many_to_one :study,
                  class: :'SurveyMoonbear::Database::StudyOrm'

      one_to_many :owned_events,
                  class: :'SurveyMoonbear::Database::EventOrm'

      plugin :uuid, field: :id
      plugin :timestamps
    end
  end
end
