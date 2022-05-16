# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a updated study, or nil
    # Usage: Service::CloseNotification.new.call(config: <config>, study_id: {...})
    class CloseNotification
      include Dry::Transaction
      include Dry::Monads

      step :get_participants_list # filter the confirmed participants
      step :get_notifications_list
      step :delete_notification_session
      step :update_study_state

      private

      # input { config:, study_id: }
      def get_participants_list(input)
        input[:participants] = Repository::For[Entity::Participant].find_study_confirmed(input[:study_id])
        Success(input)
      rescue
        Failure('Failed to get confirmed participant list.')
      end

      # input { config:, study_id:, participants: }
      def get_notifications_list(input)
        input[:notifications] = Repository::For[Entity::Notification].find_study(input[:study_id])
        Success(input)
      rescue
        Failure('Failed to get notification list.')
      end

      # input { config:, study_id:, participants:, notifications: }
      def delete_notification_session(input)
        input[:notifications].map do |notification|
          input[:participants].map do |participant|
            title = "#{notification.title}_#{notification.id}_#{participant.id}"
            Sidekiq.remove_schedule(title)
          end
        end
        Success(input)
      rescue
        Failure('Failed to delete notification session.')
      end

      # input { config:, study_id:, participants:, notifications: }
      def update_study_state(input)
        study = Repository::For[Entity::Study].update_state(input[:study_id], 'closed')
        Success(study)
      rescue
        Failure('Failed to update study state in database.')
      end
    end
  end
end
