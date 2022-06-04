# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateParticipant.new.call(config:, current_account:, study_id:, params:)
    class CreateParticipant
      include Dry::Transaction
      include Dry::Monads

      step :get_study_arn
      step :get_participant_arn
      step :store_into_database

      private

      # input { config:, current_account:, study_id:, params: }
      def get_study_arn(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])
        Success(input)
      rescue
        Failure('Failed to subscribe AWS topic.')
      end

      # input { config:, current_account:, study_id:, params:, study: }
      def get_participant_arn(input)
        if input[:study].enable_notification
          participant_arn = Messaging::NotificationSubscriber.new(input[:config])
                                                   .subscribe_topic(input[:study][:aws_arn],
                                                                    input[:params]['contact_type'],
                                                                    input[:params]['email'])
          input[:params].update({ 'aws_arn' => participant_arn, 'noti_status' => 'pending' })
        else
          input[:params].update({ 'aws_arn' => 'disable notification', 'noti_status' => 'disabled' })
        end

        Success(input)
      rescue
        Failure('Failed to subscribe AWS topic.')
      end

      # input { config:, current_account:, study_id:, params: }
      def store_into_database(input)
        new_participant = Mapper::ParticipantMapper.new.load(input)
        input[:participant] = Repository::For[new_participant.class].find_or_create(new_participant)

        Success(input)
      rescue
        Failure('Failed to store participant into database.')
      end
    end
  end
end
