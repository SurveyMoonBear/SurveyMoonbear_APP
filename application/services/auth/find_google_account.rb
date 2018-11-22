# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  # Returns an authenticated user, or nil
  # Usage: FindAuthenticatedGoogleAccount.new.call(config: {...}, code: "<params['code']>")
  class FindAuthenticatedGoogleAccount
    include Dry::Transaction
    include Dry::Monads

    step :get_access_token
    step :get_google_account
    step :build_account_entity
    step :load_from_db

    def get_access_token(config:, code:)
      access_token = HTTP.headers(accept: 'application/json')
                         .post('https://www.googleapis.com/oauth2/v4/token',
                               form: { client_id: config.GOOGLE_CLIENT_ID,
                                       client_secret: config.GOOGLE_CLIENT_SECRET,
                                       grant_type: 'authorization_code',
                                       redirect_uri: "#{config.APP_URL}/account/login/google_callback",
                                       code: code })
                         .parse['access_token']
      Success(access_token: access_token)
    rescue
      Failure('Failed to get access token')
    end

    def get_google_account(access_token:)
      google_account = HTTP.auth("Bearer #{access_token}")
                           .get('https://www.googleapis.com/oauth2/v1/userinfo?alt=json')
                           .parse
      Success(google_account: google_account, access_token: access_token)
    rescue
      Failure('Failed to get google account')
    end

    def build_account_entity(google_account:, access_token:)
      account_entity = Entity::Account.new(id: nil,
                                           email: google_account['email'],
                                           username: google_account['name'],
                                           access_token: access_token)
      Success(account_entity: account_entity)
    rescue
      Failure('Failed to build google account entity')
    end

    def load_from_db(account_entity:)
      account = Repository::For[account_entity.class].find_or_create(account_entity)
      Success(account)
    rescue
      Failure('Failed to load account from database')
    end
  end
end
