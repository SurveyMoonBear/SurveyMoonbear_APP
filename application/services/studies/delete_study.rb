# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted study
    # Usage: Service::DeleteStudy.new.call(config: <config>, current_account: <current_account>, study_id: "...")
    class DeleteStudy
      include Dry::Transaction
      include Dry::Monads

      step :get_study_arn_from_db
      step :delete_aws_topic
      step :delete_participants
      step :delete_pending_participants
      step :delete_notifications
      step :delete_record_in_database

      private

      # input { config:, current_account:, study_id:}
      def get_study_arn_from_db(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get study arn from database.')
      end

      # input { config:, current_account:, study_id:, study: }
      def delete_aws_topic(input)
        study = input[:study]
        Messaging::NotificationSubscriber.new(input[:config]).delete_topic(study.aws_arn) if study.enable_notification

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete topic on AWS.')
      end

      # input { config:, current_account:, study_id:, study: }
      def delete_participants(input)
        participants = Repository::For[Entity::Participant].find_study(input[:study_id])
        participants.map do |participant|
          DeleteParticipant.new.call(config: input[:config],
                                     current_account: input[:current_account],
                                     participant_id: participant.id)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete participants in database.')
      end

      # input { config:, current_account:, study_id:, study: }
      def delete_pending_participants(input)
        participants = Repository::For[Entity::Participant].find_study(input[:study_id])
        participants.map do |participant|
          Repository::For[Entity::Participant].delete_from(participant.id)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete pending participants in database.')
      end

      # input { config:, current_account:, study_id:, study: }
      def delete_notifications(input)
        notifications = Repository::For[Entity::Notification].find_study(input[:study_id])
        notifications.map do |notification|
          DeleteNotification.new.call(config: input[:config], notification_id: notification.id)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete notifications in database.')
      end

      # input { config:, study_id:, aws_arn: }
      def delete_record_in_database(input)
        input[:deleted_study] = Repository::For[Entity::Study].delete_from(input[:study_id])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete record in database.')
      end
    end
  end
end
