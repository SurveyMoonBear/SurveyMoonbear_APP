# frozen_string_literal: true

require 'redis'
require_relative 'secure_message'

# store value on redis
class RedisCache
  def initialize(config)
    @redis = Redis.new(
      url: config.REDISCLOUD_VISUALREPORTS_URLL,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    )
  end

  # Only set the key if it does not already exist.
  def set(key, value, ex_time = 0)
    ex_time = 60 * 60 * 24 * 30 if ex_time.zero? # default is one month

    encrypted_value = SecureMessage.encrypt(value)

    @redis.set(key, encrypted_value, nx: true, ex: ex_time)
  end

  def get(key)
    return nil unless @redis.get(key)

    SecureMessage.decrypt(@redis.get(key))
  end

  def add_to_set(key, value)
    encrypted_value = SecureMessage.encrypt(value)

    @redis.sadd(key, encrypted_value)
  end

  def exists_in_set?(key, value)
    encrypted_value = SecureMessage.encrypt(value)

    @redis.sismember(key, encrypted_value)
  end

  def get_set(key)
    encrypt_values = @redis.smembers(key)
    encrypt_values.map do |value|
      SecureMessage.decrypt(value)
    end
  end

  # Only set the key if it already exist.
  def update(key, value, ex_time = 0)
    ex_time = 60 * 60 * 24 * 30 if ex_time.zero? # default is one month

    encrypted_value = SecureMessage.encrypt(value)
    @redis.set(key, encrypted_value, xx: true, ex: ex_time)
  end

  def delete(key)
    @redis.del(key) if get(key) 
  end

  def delete_set(key)
    @redis.del(key) if get_set(key)
  end
end
