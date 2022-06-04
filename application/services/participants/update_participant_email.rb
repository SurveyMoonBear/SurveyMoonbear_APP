# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted participant entity of new title
    # Usage: Service::UpdateParticipantEmail.new.call(config: <config>, current_account: <current_account>,
    #                                                 participant: "...", new_email: "...")
    class UpdateParticipantEmail
      include Dry::Transaction
      include Dry::Monads

      step :delete_original_participant_notify_session
      step :delete_original_participant_aws_subscription
      step :delete_original_participant_calendar_subscription
      step :create_new_participant_aws_subscription

      private

      # input { config:, current_account:, participant:, new_email: }
      def delete_original_participant_notify_session(input)
        participant = input[:participant]
        if participant.noti_status == 'confirmed' && participant.study.state == 'started'
          notifications = Repository::For[Entity::Notification].find_study(participant.study.id)
          DeleteNotificationSession.new.call(config: input[:config],
                                             notifications: notifications,
                                             participants: [participant])
        end
        Success(input)
      rescue
        Failure('Failed to delete original participant notification session')
      end

      # input { config:, current_account:, participant:, new_email: }
      def delete_original_participant_aws_subscription(input)
        participant = input[:participant]
        if participant.noti_status != 'disabled' && participant.noti_status != 'pending'
          Messaging::NotificationSubscriber.new(input[:config]).delete_subscription(participant.aws_arn)
        end
        Success(input)
      rescue
        Failure('Failed to delete original participant AWS subscription')
      end

      # input { config:, current_account:, participant:, new_email: }
      def delete_original_participant_calendar_subscription(input)
        participant = input[:participant]
        if participant.act_status == 'subscribed'
          UnsubscribeCalendar.new.call(config: input[:config],
                                       current_account: input[:current_account],
                                       participant_id: participant.id,
                                       calendar_id: participant.email)
        end
        Success(input)
      rescue
        Failure('Failed to delete original participant calendar subscription')
      end

      # input { config:, current_account:, participant:, new_email: }
      def create_new_participant_aws_subscription(input)
        participant = input[:participant]
        if participant.noti_status != 'disabled'
          Messaging::NotificationSubscriber.new(input[:config]).subscribe_topic(participant.study.aws_arn,
                                                                      participant.contact_type,
                                                                      input[:new_email],
                                                                      participant.id)
          Repository::For[Entity::Participant].update_noti_status(participant.id, 'pending')
        end
        Success(input)
      rescue
        Failure('Failed to create new participant AWS subscription')
      end
    end
  end
end
