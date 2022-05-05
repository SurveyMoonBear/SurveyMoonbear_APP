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

      def store_into_database(input)
        track_activity = !input[:params]['track_activity'].nil?
        enable_notification = !input[:params]['enable_notification'].nil?
        input[:params].update('track_activity' => track_activity,
                              'enable_notification' => enable_notification,
                              'aws_arn' => 'checking enable notification or not')
        new_study = Mapper::StudyMapper.new.load(input[:params], input[:current_account])
        study = Repository::For[new_study.class].create_from(new_study)
        input[:study] = study

        Success(input)
      rescue
        Failure('Failed to store into database.')
      end

      def get_study_arn(input)
        if input[:params]['enable_notification']
          study_arn = Messaging::Notification.new(input[:config]).create_topic(input[:study][:id])
          input[:params]['aws_arn'] = study_arn
        else
          input[:params]['aws_arn'] = 'disable notification'
        end

        Success(input)
      rescue
        Failure('Failed to get aws_arn.')
      end

      def update_study_arn(input)
        study = input[:study]
        aws_arn = input[:params]['aws_arn']
        updated_study = Repository::For[study.class].update_arn(study.id, aws_arn)

        Success(updated_study)
      rescue
        Failure('Failed to update study aws_arn in database')
      end
    end
  end
end
