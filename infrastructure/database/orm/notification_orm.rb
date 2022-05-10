# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Notification Entities
    class NotificationOrm < Sequel::Model(:notifications)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'
      many_to_one :study,
                  class: :'SurveyMoonbear::Database::StudyOrm'
      many_to_one :survey,
                  class: :'SurveyMoonbear::Database::SurveyOrm'

      plugin :timestamps
    end
  end
end
