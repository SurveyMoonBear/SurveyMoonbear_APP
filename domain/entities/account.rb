# frozen_string_literal: false

require 'dry-struct'

module SurveyMoonbear
  module Entity
    # Domain entity object for any google account
    class Account < Dry::Struct
      attribute :id, Types::Int.optional
      attribute :email, Types::Strict::String
      attribute :username, Types::Strict::String
      attribute :access_token, Types::Strict::String
    end
  end
end
