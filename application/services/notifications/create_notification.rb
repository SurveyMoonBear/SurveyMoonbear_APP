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
      # step :create_schedule

      private

      # input { config:, current_account:, study_id:, params: }
      def store_into_database(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])
        input[:survey] = Repository::For[Entity::Survey].find_id(input[:params]['survey_id'])
        new_notification = Mapper::NotificationMapper.new.load(input)
        input[:notification] = Repository::For[new_notification.class].find_or_create(new_notification)

        Success(input)
      rescue
        Failure('Failed to subscribe AWS topic.')
      end

      # TODO: Create schedule
      # def create_schedule(input)
      #   notification = input[:notification]
      #   aws_arn = input[:params]['aws_arn']
      #   noti_status = input[:params]['noti_status']
      #   notification = Repository::For[notification.class].update_arn(notification.id, aws_arn, noti_status)

      #   Success(updated_notification)
      # rescue
      #   Failure('Failed to update notification AWS subscription arn in database')
      # end
    end
  end
end
