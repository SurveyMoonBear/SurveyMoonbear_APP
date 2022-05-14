# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted participant
    # Usage: Service::DeleteParticipant.new.call(config: <config>, participant_id: "...")
    class DeleteParticipant
      include Dry::Transaction
      include Dry::Monads

      step :get_participant_arn_from_db
      step :delete_aws_subscription
      # step :delete_schedule
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

      # input { config:, participant_id:, aws_arn: }
      def delete_aws_subscription(input)
        participant = input[:participant]
        # only can delete confirmed participants
        if participant.noti_status == 'confirmed'
          Messaging::Notification.new(input[:config]).delete_subscription(participant.aws_arn)
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete topic on AWS.')
      end

      # # input { config:, participant_id:, aws_arn: }
      # def delete_schedule(input)
      #   # Schedule: delete related schedule
      #   if enable_notification
      #     notification_list = notification.where(participant_id: input[:participant_id]).all
      #     notification_list.map { |notification| DeleteNotification.new.call(id: notification.id) }
      #   end
      #   Success(input)
      # rescue StandardError => e
      #   puts e
      #   Failure('Failed to delete schedule in database.')
      # end

      # input { config:, participant_id:, aws_arn: }
      def delete_record_in_database(input)
        participant = input[:participant]

        input[:deleted_participant] = if participant.noti_status == 'confirmed' || participant.noti_status == 'disabled'
                                        Repository::For[Entity::Participant].delete_from(participant.id)
                                      else
                                        'It only can delete confirmed participants.'
                                      end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete record in database.')
      end
    end
  end
end
