require 'base64'
require 'rbnacl'
require 'redis'
require_relative 'secure_message'

# Encrypt and Decrypt JSON encoded sessions
class SecureSession
  ## Any use of this library must setup configuration information
  def self.setup(config)
    @config = config
  end

  ## Class methods to create and retrieve cookie salt
  SESSION_SECRET_BYTES = 64

  # Generate secret for sessions
  def self.generate_secret
    secret = RbNaCl::Random.random_bytes(SESSION_SECRET_BYTES)
    Base64.strict_encode64 secret
  end

  def self.secret
    Base64.strict_decode64 @config.SESSION_SECRET
  rescue
    nil
  end

  def self.wipe_redis_sessions
    redis = Redis.new(
      url: @config.REDIS_URLL,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    )
    redis.keys.each { |session_id| redis.del session_id }
  end

  ## Instance methods to store and retrieve encrypted session data
  def initialize(session)
    @session = session
  end

  def set(key, value)
    # encrypted_value = SecureMessage.encrypt(value)
    # @session[key] = Base64.strict_encode64(encrypted_value)
    @session[key] = SecureMessage.encrypt(value)
  end

  def get(key)
    return nil unless @session[key]
    SecureMessage.decrypt(@session[key])
  end

  def delete(key)
    @session.delete(key)
  end
end
