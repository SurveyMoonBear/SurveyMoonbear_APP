# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class StudyOrm < Sequel::Model(:studies)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'
      one_to_many :owned_participants,
                  class: :'SurveyMoonbear::Database::ParticipantOrm',
                  key: :study_id
      one_to_many :owned_notifications,
                  class: :'SurveyMoonbear::Database::NotificationOrm',
                  key: :study_id

      plugin :uuid, field: :id
      plugin :timestamps
    end
  end
end
