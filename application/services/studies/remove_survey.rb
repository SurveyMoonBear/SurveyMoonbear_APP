# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted study entity of new title
    # Usage: Service::RemoveSurvey.new.call(config: <config>, study_id: "...", survey_id: "...")
    class RemoveSurvey
      include Dry::Transaction
      include Dry::Monads

      step :delete_notifications
      step :remove_survey

      private

      # input { config:, study_id:, survey_id: }
      def delete_notifications(input)
        notifications = Repository::For[Entity::Notification].find_survey(input[:survey_id])
        notifications.map do |notification|
          DeleteNotification.new.call(config: input[:config], notification_id: notification.id)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete related notifications.')
      end

      # input { config:, study_id:, survey_id: }
      def remove_survey(input)
        survey = Repository::For[Entity::Study].remove_survey(input[:study_id], input[:survey_id])
        Success(survey)
      rescue StandardError => e
        puts e
        Failure('Failed to remove survey from study.')
      end
    end
  end
end
