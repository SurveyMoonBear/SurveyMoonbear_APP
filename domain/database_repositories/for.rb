# frozen_string_literal: true

module SurveyMoonbear
  module Repository
    For = {
      Entity::Account => Accounts,
      Entity::Survey  => Surveys,
      Entity::Launch  => Launches,
      Entity::VisualReport => VisualReports,
      Entity::Study => Studies,
      Entity::Participant => Participants,
      Entity::Notification => Notifications
    }.freeze
  end
end
