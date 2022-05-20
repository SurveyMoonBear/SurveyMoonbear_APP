# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::ConfirmParticipantsNotiStatus.new.call(config: <config>, study: {...},
    #                                                        participant: {...}, arn: {...})
    class ConfirmParticipantsNotiStatus
      include Dry::Transaction
      include Dry::Monads

      step :update_participants_new_arn_in_db
      step :create_notification_session

      private

      # input { config:, study_id:, study:, upd_arn:, participants: }
      def update_participants_new_arn_in_db(input)
        input[:participant] = Repository::For[Entity::Participant].update_arn(input[:participant].id,
                                                                              input[:arn], 'confirmed')
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to update participants new AWS arn in db.')
      end

      # input { config:, study_id:, study:, upd_arn:, participants: }
      def create_notification_session(input)
        if input[:study].state == 'started'
          notifications = Repository::For[Entity::Notification].find_study(input[:study].id)
          CreateNotificationSession.new.call(config: input[:config],
                                             notifications: notifications,
                                             participants: [input[:participant]])
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to create notification session')
      end
    end
  end
end
