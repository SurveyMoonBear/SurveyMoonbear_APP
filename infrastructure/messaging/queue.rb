# frozen_string_literal: true

require 'aws-sdk-sqs'

module SurveyMoonbear
  module Messaging
    # Queue wrapper for AWS SQS
    class Queue
      def initialize(queue_url, config)
        @queue_url = queue_url
        sqs = Aws::SQS::Client.new(
          access_key_id: config.AWS_ACCESS_KEY_ID,
          secret_access_key: config.AWS_SECRET_ACCESS_KEY,
          region: config.AWS_REGION
        )
        @queue = Aws::SQS::Queue.new(url: queue_url, client: sqs)
      end

      ## Send message(str) to queue
      # Usage:
      #   q = Messaging::Queue.new(config.RES_QUEUE_URL, config)
      #   q.send({data: "hello"}.to_json)
      def send(message)
        @queue.send_message(message_body: message)
      end
    end
  end
end