# frozen_string_literal: true

require 'dry-struct'

require_relative 'response.rb'

module SurveyMoonbear
  module Entity
    # Domain entity object for any survey
    class Launch < Dry::Struct
      attribute :id, Types::String.optional
      attribute :started_at, Types::DateTime
      attribute :closed_at, Types::DateTime.optional
      attribute :state, Types::Strict::String
      attribute :responses, Types::Strict::Array.member(Response).optional
    end
  end
end
