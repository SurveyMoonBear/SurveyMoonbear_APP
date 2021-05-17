# frozen_string_literal: true

require_relative 'response'

module SurveyMoonbear
  module Entity
    # Domain entity object for any survey
    class Launch < Dry::Struct
      include Dry.Types
      attribute :id, String.optional
      attribute :started_at, Strict::Time
      attribute :closed_at, Strict::Time.optional
      attribute :state, Strict::String
      attribute :responses, Strict::Array.of(Response).optional
    end
  end
end
