# frozen_string_literal: false

module SurveyMoonbear
  module Entity
    # Domain entity object for any google account
    class Account < Dry::Struct
      include Dry.Types
      attribute :id, Integer.optional
      attribute :email, Strict::String
      attribute :username, Strict::String
      attribute :access_token, Strict::String
      attribute :refresh_token, Strict::String.optional
    end
  end
end
