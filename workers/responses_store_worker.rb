# frozen_string_literal: true

require_relative '../domain/entities/init.rb'
require_relative '../domain/database_repositories/init.rb'

require 'econfig'
require 'shoryuken'
require 'sequel'

module ResponsesStore
  class Worker
    extend Econfig::Shortcut
    Econfig.env = ENV['RACK_ENV'] || 'development'
    Econfig.root = File.expand_path('..', File.dirname(__FILE__))

    Shoryuken.sqs_client = Aws::SQS::Client.new(
      access_key_id: config.AWS_ACCESS_KEY_ID,
      secret_access_key: config.AWS_SECRET_ACCESS_KEY,
      region: config.AWS_REGION
    )

    include Shoryuken::Worker
    Shoryuken.sqs_client_receive_message_opts = { wait_time_seconds: 20 }
    shoryuken_options queue: config.RES_QUEUE_URL, auto_delete: true

    def perform(sqs_msg, msg_body)
      store_responses(JSON.parse(msg_body))
    end

    private

    def store_responses(response_hashes)
      db = Sequel.connect(ENV['DATABASE_URL'])
      db[:responses].multi_insert(response_hashes)
    end
  end
end