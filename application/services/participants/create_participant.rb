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

      step :store_into_database
      step :get_participant_arn
      step :update_participant_arn

      private

      # input { config:, current_account:, study_id:, params: }
      def store_into_database(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])
        new_participant = Mapper::ParticipantMapper.new.load(input)
        input[:participant] = Repository::For[new_participant.class].find_or_create(new_participant)

        Success(input)
      rescue
        Failure('Failed to store participant into database.')
      end

      # TODO: sms contact_type
      # input { config:, current_account:, study_id:, params:, study:, participant: }
      def get_participant_arn(input)
        if input[:study][:enable_notification]
          participant_arn = Messaging::Notification.new(input[:config])
                                                   .subscribe_topic(input[:study][:aws_arn],
                                                                    input[:participant][:contact_type],
                                                                    input[:participant][:email],
                                                                    input[:participant][:id])
          input[:aws_arn] = participant_arn
          input[:noti_status] = 'pending'
        else
          input[:aws_arn] = 'disable notification'
          input[:noti_status] = 'disabled'
        end

        Success(input)
      rescue
        Failure('Failed to subscribe AWS topic.')
      end

      # input { config:, current_account:, study_id:, params:,
      #         study:, participant:, aws_arn:, noti_status: }
      def update_participant_arn(input)
        updated_participant = Repository::For[input[:participant].class].update_arn(input[:participant].id,
                                                                                    input[:aws_arn],
                                                                                    input[:noti_status])

        Success(updated_participant)
      rescue
        Failure('Failed to update participant AWS subscription arn in database')
      end
    end
  end
end
