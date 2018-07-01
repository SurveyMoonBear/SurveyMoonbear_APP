# frozen_string_literal: true

require 'dry-struct'

require_relative 'page.rb'
require_relative 'launch.rb'

module SurveyMoonbear
  module Entity
    # Domain entity object for any survey
    class Survey < Dry::Struct
      attribute :id, Types::String.optional
      attribute :owner, Account
      attribute :launch_id, Types::String.optional
      attribute :origin_id, Types::Strict::String
      attribute :title, Types::Strict::String
      attribute :created_at, Types::Strict::Time.optional
      attribute :state, Types::Strict::String.optional
      attribute :pages, Types::Strict::Array.member(Page)
      attribute :launches, Types::Strict::Array.member(Launch).optional
    end
  end
end
