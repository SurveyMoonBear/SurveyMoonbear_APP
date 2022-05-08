# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateParticipant.new.call(config: <config>, current_account: {...}, params: {...})
    class CreateParticipant
      include Dry::Transaction
      include Dry::Monads

      step :store_into_database
      step :get_participant_arn
      step :update_participant_arn

      private

      def store_into_database(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])
        input[:params].update('status' => 'checking',
                              'aws_arn' => 'checking enable notification or not')
        new_participant = Mapper::ParticipantMapper.new.load(input)
        participant = Repository::For[new_participant.class].find_or_create(new_participant)
        input[:participant] = participant

        Success(input)
      rescue
        Failure('Failed to store participant into database.')
      end

      # TODO: sms contact_type
      def get_participant_arn(input)
        if input[:study][:enable_notification]
          participant_arn = Messaging::Notification.new(input[:config])
                                                   .subscribe_topic(input[:study][:aws_arn],
                                                                    input[:participant][:contact_type],
                                                                    input[:participant][:email],
                                                                    input[:participant][:id])
          input[:params]['aws_arn'] = participant_arn
          input[:params]['status'] = 'pending'
        else
          input[:params]['aws_arn'] = 'disable notification'
          input[:params]['status'] = 'disabled'
        end

        Success(input)
      rescue
        Failure('Failed to subscribe AWS topic.')
      end

      def update_participant_arn(input)
        participant = input[:participant]
        aws_arn = input[:params]['aws_arn']
        status = input[:params]['status']
        updated_participant = Repository::For[participant.class].update_arn(participant.id, aws_arn, status)

        Success(updated_participant)
      rescue
        Failure('Failed to update participant AWS subscription arn in database')
      end
    end
  end
end
