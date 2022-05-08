# frozen_string_literal: true

require 'aws-sdk-sns'

module SurveyMoonbear
  module Messaging
    # Notification wrapper for AWS SNS
    class Notification
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

      def subscribe_topic(topic_arn, protocol, endpoint, uuid)
        @sns_client.subscribe(topic_arn: topic_arn,
                              protocol: protocol,
                              endpoint: endpoint,
                              attributes: {
                                'FilterPolicy' => "{\"uuid\": [\"#{uuid}\", \"all\"]}"
                              })[:subscription_arn]
      end

      def confirm_subscriptions(topic_arn)
        topic = @sns_resource.topic(topic_arn)
        updated_subscriptions_arn = {}
        topic.subscriptions.map do |subscription|
          next if subscription.arn == 'PendingConfirmation'

          updated_subscriptions_arn.update({ subscription.attributes['Endpoint'] => subscription.arn })
        end
        updated_subscriptions_arn
      end

      def delete_subscription(subscription_arn)
        @sns_resource.subscription(subscription_arn).delete
      end
    end
  end
end
