# frozen_string_literal: false

require 'dry-struct'

module SurveyMoonbear
  module Entity
    # Domain entity object for any survey
    class Survey < Dry::Struct
      attribute :id, Types::Int.optional
      attribute :owner, Account
      attribute :origin_id, Types::Strict::String
      attribute :title, Types::Strict::String
    end
  end
end
