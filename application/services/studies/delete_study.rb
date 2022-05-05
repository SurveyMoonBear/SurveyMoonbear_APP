# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return a deleted study
    # Usage: Service::DeleteStudy.new.call(config: <config>, study_id: "...")
    class DeleteStudy
      include Dry::Transaction
      include Dry::Monads

      step :get_study_arn_from_db
      step :delete_aws_topic
      # step :delete_schedule
      step :delete_record_in_database

      private

      # input { config:, study_id:}
      def get_study_arn_from_db(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get study arn from database.')
      end

      # input { config:, study_id:, aws_arn: }
      def delete_aws_topic(input)
        study = input[:study]
        Messaging::Notification.new(input[:config]).delete_topic(study.aws_arn) if study.enable_notification

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete topic on AWS.')
      end

      # # input { config:, study_id:, aws_arn: }
      # def delete_schedule(input)
      #   # Schedule: delete related schedule
      #   if enable_notification
      #     notification_list = notification.where(study_id: input[:study_id]).all
      #     notification_list.map { |notification| DeleteNotification.new.call(id: notification.id) }
      #   end
      #   Success(input)
      # rescue StandardError => e
      #   puts e
      #   Failure('Failed to delete schedule in database.')
      # end

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
