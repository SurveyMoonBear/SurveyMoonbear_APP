# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateNotification.new.call(config: <config>, current_account: {...},
    #                                             study_id: {...}, params: {...})
    class CreateNotification
      include Dry::Transaction
      include Dry::Monads

      step :store_into_database
      step :create_notification_session

      private

      # input { config:, current_account:, study_id:, params: }
      def store_into_database(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])
        input[:survey] = Repository::For[Entity::Survey].find_id(input[:params]['survey_id'])
        new_notification = Mapper::NotificationMapper.new.load(input)
        input[:notification] = Repository::For[new_notification.class].find_or_create(new_notification)

        Success(input)
      rescue
        Failure('Failed to store notification into database.')
      end

      # input { config:, current_account:, study_id:, params:, study:, survey:, notification }
      def create_notification_session(input)
        if input[:study].state == 'started'
          participants = Repository::For[Entity::Participant].find_study_confirmed(input[:study_id])
          participants.map do |participant|
            survey_link = "#{input[:config].APP_URL}/onlinesurvey/#{input[:survey].id}/#{input[:survey].launch_id}"
            CreateNotificationSession.new.call(notification: input[:notification],
                                               study: input[:study],
                                               survey_link: survey_link,
                                               participant_id: participant.id)
          end
        end
        Success(input[:notification])
      rescue
        Failure('Failed to create notification session when study is started.')
      end
    end
  end
end
