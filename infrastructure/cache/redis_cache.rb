# frozen_string_literal: true

require 'redis'

module SurveyMoonbear
  module Cache
    # Redis client utility
    class Client
      def initialize(config)
        @redis = Redis.new(
          url: config.REDISCLOUD_URL,
          ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
        )
      end

      def keys
        @redis.keys
      end

      def wipe
        keys.each { |key| @redis.del(key) }
      end

      def add_to_set(key, value)
        @redis.sadd?(key, value)
      end

      def exists_in_set?(key, value)
        @redis.sismember(key, value)
      end

      def get_set(key)
        @redis.smembers(key)
      end
    end
  end
end
