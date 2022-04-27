# frozen_string_literal: true

require 'redis'

module SurveyMoonbear
  module Cache
    # Redis client utility
    class Client
      def initialize(config)
        @redis = Redis.new(url: config.REDISCLOUD_URL)
      end

      def keys
        @redis.keys
      end

      def wipe
        keys.each { |key| @redis.del(key) }
      end
    end
  end
end