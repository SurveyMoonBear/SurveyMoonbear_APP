# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::StartNotification.new.call(config: <config>, study_id: {...})
    class StartNotification
      include Dry::Transaction
      include Dry::Monads

      step :get_participants_list # filter the confirmed participants
      step :get_notifications_list # get related survey link
      step :create_notification_session
      step :update_study_state

      private

      # input { config:, study_id: }
      def get_participants_list(input)
        UpdateParticipantsNotiStatus.new.call(config: input[:config], study_id: input[:study_id])
        input[:participants] = Repository::For[Entity::Participant].find_study_confirmed(input[:study_id])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get confirmed participant list')
      end

      # input { config:, study_id:, participants: }
      def get_notifications_list(input)
        input[:notifications] = Repository::For[Entity::Notification].find_study(input[:study_id])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get notification list.')
      end

      # input { config:, study_id:, participants:, notifications: }
      def create_notification_session(input)
        CreateNotificationSession.new.call(config: input[:config],
                                           notifications: input[:notifications],
                                           participants: input[:participants])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to create notification session.')
      end

      # input { config:, study_id:, participants:, notifications: }
      def update_study_state(input)
        study = Repository::For[Entity::Study].update_state(input[:study_id], 'started')
        Success(study)
      rescue StandardError => e
        puts e
        Failure('Failed to update study state in database.')
      end
    end
  end
end
