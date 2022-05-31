require 'redis'
require_relative 'secure_message'

# store value on redis
class RedisCloud
  def initialize(config)
    @redis = Redis.new(url: config.REDIS_URL + config.REDIS_VISUAL_REPORT)
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

  # Only set the key if it already exist.
  def update(key, value, ex_time = 0)
    ex_time = 60 * 60 * 24 * 30 if ex_time.zero? # default is one month

    encrypted_value = SecureMessage.encrypt(value)
    @redis.set(key, encrypted_value, xx: true, ex: ex_time)
  end

  def delete(key)
    @redis.del(key)
  end
end
