# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::CreateStudy.new.call(config: <config>, current_account: {...}, params: {...})
    class CreateStudy
      include Dry::Transaction
      include Dry::Monads

      step :store_into_database
      step :get_study_arn
      step :update_study_arn

      private

      # input { config:, current_account:, params: }
      def store_into_database(input)
        new_study = Mapper::StudyMapper.new.load(input[:params], input[:current_account])
        input[:study] = Repository::For[new_study.class].create_from(new_study)

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to create a study and store it into database.')
      end

      # input { config:, current_account:, params:, study: }
      def get_study_arn(input)
        if input[:study].enable_notification
          study_arn = Messaging::NotificationSubscriber.new(input[:config]).create_topic(input[:study][:id])
          input[:aws_arn] = study_arn
        else
          input[:aws_arn] = 'disable notification'
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to create AWS topic to get study AWS arn.')
      end

      # input { config:, current_account:, params:, study:, aws_arm: }
      def update_study_arn(input)
        updated_study = Repository::For[input[:study].class].update_arn(input[:study].id, input[:aws_arn])

        Success(updated_study)
      rescue StandardError => e
        puts e
        Failure('Failed to update study AWS arn in database.')
      end
    end
  end
end
