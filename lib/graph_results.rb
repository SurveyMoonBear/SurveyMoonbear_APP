require 'redis'
require_relative 'secure_message'

# store graph results on redis
class GraphResults
  def initialize(config)
    @redis = Redis.new(url: config.REDIS_URL + '/2')
  end

  # Only set the key if it does not already exist.
  def set(key, value)
    encrypted_value = SecureMessage.encrypt(value)
    @redis.set(key, encrypted_value, nx: true)
  end

  def get(key)
    return nil unless @redis.get(key)

    SecureMessage.decrypt(@redis.get(key))
  end

  # Only set the key if it already exist.
  def update(key, value)
    encrypted_value = SecureMessage.encrypt(value)
    @redis.set(key, encrypted_value, :xx => true)
  end

  def delete(key)
    @redis.del(key)
  end
end
