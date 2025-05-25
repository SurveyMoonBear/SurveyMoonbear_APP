# frozen_string_literal: true

module SurveyMoonbear
  module Repository
    For = {
      Entity::Account => Accounts,
      Entity::AccountSurvey => AccountSurveys,
      Entity::Survey  => Surveys,
      Entity::Launch  => Launches,
      Entity::VisualReport => VisualReports,
      Entity::Study => Studies,
      Entity::Participant => Participants,
      Entity::Notification => Notifications,
      Entity::Event => Events
    }.freeze

     def self.klass(entity_klass)
        ENTITY_REPOSITORY[entity_klass]
      end

      def self.entity(entity_object)
        ENTITY_REPOSITORY[entity_object.class]
      end
      
  end
end
