# frozen_string_literal: true

require_relative 'page'
require_relative 'launch'

module SurveyMoonbear
  module Entity
    # Domain entity object for any survey
    class Survey < Dry::Struct
      include Dry.Types
      attribute :id, String.optional
      attribute :owner, Account
      attribute :launch_id, String.optional
      attribute :origin_id, Strict::String
      attribute :title, Strict::String
      attribute :created_at, Strict::Time.optional
      attribute :state, Strict::String.optional
      attribute :options, Strict::String.optional
      attribute :pages, Strict::Array.of(Page)
      attribute :launches, Strict::Array.of(Launch).optional
    end
  end
end
