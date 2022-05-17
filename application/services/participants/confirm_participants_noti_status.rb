# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateParticipant.new.call(config: <config>, study_id: {...})
    class ConfirmParticipantsNotiStatus
      include Dry::Transaction
      include Dry::Monads

      step :get_study_arn_from_db
      step :get_updated_participants_arn
      step :update_participants_arn_in_db
      step :create_notification_session

      private

      # input { config:, study_id:}
      def get_study_arn_from_db(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get study arn from database.')
      end

      # input { config:, study_id:, study: }
      def get_updated_participants_arn(input)
        input[:updated_sub_arn] = Messaging::Notification.new(input[:config])
                                                         .confirm_subscriptions(input[:study].aws_arn)
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get updated participant arn.')
      end

      # input { config:, study_id:, study:, updated_sub_arn: }
      def update_participants_arn_in_db(input)
        participants = Repository::For[Entity::Participant].find_study(input[:study].id)
        participants.each do |participant|
          next unless participant.noti_status == 'pending'

          sub_arn = input[:updated_sub_arn][participant.email]
          params = { "aws_arn": sub_arn, "noti_status": 'confirmed' } unless sub_arn.nil?
          UpdateParticipant.new.call(config: input[:config],
                                     participant_id: participant.id,
                                     params: params)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to update participants AWS arn.')
      end

      # input { config:, study_id:, study:, updated_sub_arn: }
      def create_notification_session(input)
        input[:participants] = Repository::For[Entity::Participant].find_study_confirmed(input[:study_id])
        input[:notifications] = Repository::For[Entity::Notification].find_study(input[:study_id])
        input[:notifications].map do |notification|
          input[:participants].map do |participant|
            survey_link = "#{input[:config].APP_URL}/onlinesurvey/#{notification.survey.id}/#{notification.survey.launch_id}"
            CreateNotificationSession.new.call(notification: notification,
                                               study: participant.study,
                                               survey_link: survey_link,
                                               participant_id: participant.id)
          end
        end
        Success(participant)
      rescue
        Failure('Failed to create notification session')
      end
    end
  end
end
