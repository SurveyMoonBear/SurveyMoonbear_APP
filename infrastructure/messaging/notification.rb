# frozen_string_literal: true

require 'aws-sdk-sns'

module SurveyMoonbear
  module Messaging
    # Notification wrapper for AWS SNS
    class Notification
      # IDLE_TIMEOUT = 5 # seconds

      def initialize(config)
        @config = config
        @sns_client = Aws::SNS::Client.new(
          access_key_id: config.AWS_ACCESS_KEY_ID,
          secret_access_key: config.AWS_SECRET_ACCESS_KEY,
          region: config.AWS_REGION
        )
      end

      def create_topic(study_id)
        @sns_client.create_topic(name: study_id)[:topic_arn]
      end
    end
  end
end
