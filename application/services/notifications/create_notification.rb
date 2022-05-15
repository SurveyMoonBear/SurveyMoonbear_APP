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
    end
  end
end
