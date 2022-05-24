# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted participant
    # Usage: Service::DeleteParticipant.new.call(config: <config>, current_account: <current_account>, participant_id: "...")
    class DeleteParticipant
      include Dry::Transaction
      include Dry::Monads

      step :get_participant_arn_from_db
      step :delete_notification_session
      step :delete_aws_subscription
      step :delete_events
      step :unsubscribe_calendar
      step :delete_record_in_database

      private

      # input { config:, participant_id:}
      def get_participant_arn_from_db(input)
        input[:participant] = Repository::For[Entity::Participant].find_id(input[:participant_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get participant arn from database.')
      end

      # input { config:, participant_id:, participant: }
      def delete_notification_session(input)
        participant = input[:participant]
        if participant.study.state == 'started'
          notifications = Repository::For[Entity::Notification].find_study(participant.study.id)
          DeleteNotificationSession.new.call(config: input[:config],
                                             notifications: notifications,
                                             participants: [participant])
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete notification from session.')
      end

      # input { config:, participant_id:, participant: }
      def delete_aws_subscription(input)
        participant = input[:participant]
        # only can delete confirmed participants
        if participant.noti_status == 'confirmed' || participant.noti_status == 'turn_off'
          Messaging::NotificationSubscriber.new(input[:config]).delete_subscription(participant.aws_arn)
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete subscription on AWS.')
      end

      # input { config:, participant_id:, participant: }
      def delete_events(input)
        events = Repository::For[Entity::Event].find_participant(input[:participant_id])
        Repository::For[Entity::Event].delete_all(events)
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete participants event from db.')
      end

      # input { config:, participant_id:, participant: }
      def unsubscribe_calendar(input)
        if input[:participant].act_status == 'subscribed'
          UnsubscribeCalendar.new.call(config: input[:config],
                                       current_account: input[:current_account],
                                       participant_id: input[:participant_id],
                                       calendar_id: input[:participant].email)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to unsubscribe participant.')
      end

      # input { config:, participant_id:, aws_arn: }
      def delete_record_in_database(input)
        participant = input[:participant]

        input[:deleted_participant] = if participant.noti_status == 'pending'
                                        participant
                                      else
                                        Repository::For[Entity::Participant].delete_from(participant.id)
                                      end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete record in database.')
      end
    end
  end
end
