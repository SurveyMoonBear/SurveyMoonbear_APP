# frozen_string_literal: true

require 'aws-sdk-sns'

module SurveyMoonbear
  module Messaging
    # Notification wrapper for AWS SNS
    class Notification
      # IDLE_TIMEOUT = 5 # seconds

      def initialize(config)
        @config = config
        @config_aws_hash = {
          access_key_id: config.AWS_ACCESS_KEY_ID,
          secret_access_key: config.AWS_SECRET_ACCESS_KEY,
          region: config.AWS_REGION
        }
        @sns_client = Aws::SNS::Client.new(@config_aws_hash)
        @sns_resource = Aws::SNS::Resource.new(@config_aws_hash)
      end

      def create_topic(study_id)
        @sns_client.create_topic(name: study_id)[:topic_arn]
      end

      def delete_topic(study_arn)
        topic = @sns_resource.topic(study_arn)
        unless topic.subscriptions.first.nil?
          topic.subscriptions.each do |subscribe|
            subscribe.delete unless subscribe.arn == 'PendingConfirmation'
          end
        end
        topic.delete
      end
    end
  end
end
