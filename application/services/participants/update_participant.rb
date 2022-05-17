# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted participant entity of new title
    # Usage: Service::UpdateParticipant.new.call(config: <config>, participant_id: "...", params: "...")
    class UpdateParticipant
      include Dry::Transaction
      include Dry::Monads

      step :check_email_changing
      step :turn_on_off_noti
      step :update_participant

      private

      # input { config:, participant_id:, params: }
      def check_email_changing(input)
        participant = Repository::For[Entity::Participant].find_id(input[:participant_id])
        new_email = input[:params]['email']
        if !new_email.nil? && participant.study.enable_notification && participant.email != new_email
          # delete original arn:
          # 1. pending -> no need to delete and directly a new create
          # 2. confirmed
          if participant.noti_status == 'confirmed' || participant.noti_status == 'turn_off'
            Messaging::Notification.new(input[:config]).delete_subscription(participant.aws_arn)
          end
          # new create arn
          new_arn = Messaging::Notification.new(input[:config])
                                           .subscribe_topic(participant.study.aws_arn,
                                                            participant.contact_type,
                                                            new_email,
                                                            participant.id)
          input[:params]['aws_arn'] = new_arn
          input[:params]['noti_status'] = 'pending'
        end
        Success(input)
      rescue
        Failure('Failed to update participant aws arn')
      end

      # input { config:, participant_id:, params: }
      def turn_on_off_noti(input)
        participant = Repository::For[Entity::Participant].find_id(input[:participant_id])
        if participant.study.state == 'started'
          case input[:params]['noti_status']
          when 'confirmed'
            notifications = Repository::For[Entity::Notification].find_study(participant.study.id)
            notifications.map do |notification|
              survey_link = "#{input[:config].APP_URL}/onlinesurvey/#{notification.survey.id}/#{notification.survey.launch_id}"
              CreateNotificationSession.new.call(notification: notification,
                                                 study: participant.study,
                                                 survey_link: survey_link,
                                                 participant_id: participant.id)
            end
          when 'turn_off'
            notifications = Repository::For[Entity::Notification].find_study(participant.study.id)
            notifications.map do |notification|
              title = "#{notification.title}_#{notification.id}_#{participant.id}"
              Sidekiq.remove_schedule(title)
            end
          end
        end
        Success(input)
      rescue
        Failure('Failed to update participant aws arn')
      end

      # input { participant_id:, params: }
      def update_participant(input)
        updated_participant = Repository::For[Entity::Participant].update(input[:participant_id], input[:params])
        Success(updated_participant)
      rescue
        Failure('Failed to update participant title in database')
      end
    end
  end
end
