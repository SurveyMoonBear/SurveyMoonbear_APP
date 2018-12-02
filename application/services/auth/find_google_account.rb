# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns an authenticated user, or nil
    # Usage: Service::FindAuthenticatedGoogleAccount.new.call(config: {...}, code: "<params['code']>")
    class FindAuthenticatedGoogleAccount
      include Dry::Transaction
      include Dry::Monads

      step :get_access_token
      step :get_google_account
      step :build_account_entity
      step :load_from_db

      private

      # input {config:, code:}
      def get_access_token(input)
        input[:access_token] = Google::Auth.new(input[:config])
                                           .get_access_token(input[:code])
        Success(input)
      rescue
        Failure('Failed to get access token')
      end

      # input {config:, code:, access_token:}
      def get_google_account(input)
        input[:google_account] = Google::Auth.new(input[:config])
                                             .get_google_account(input[:access_token])
        Success(input)
      rescue
        Failure('Failed to get google account')
      end

      # input {config:, code:, access_token:, google_account:}
      def build_account_entity(input)
        input[:account_entity] = Entity::Account.new(id: nil,
                                                    email: input[:google_account]['email'],
                                                    username: input[:google_account]['name'],
                                                    access_token: input[:access_token])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to build google account entity')
      end

      # input {config:, code:, access_token:, google_account:, account_entity:}
      def load_from_db(input)
        account = Repository::For[ input[:account_entity].class ].find_or_create(input[:account_entity])
        Success(account)
      rescue StandardError => e
        puts e
        Failure('Failed to load account from database')
      end
    end
  end
end
