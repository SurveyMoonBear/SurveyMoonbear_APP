# frozen_string_literal: true

require 'dry-struct'

require_relative 'page.rb'

module SurveyMoonbear
  module Entity
    # Domain entity object for any survey
    class Survey < Dry::Struct
      attribute :id, Types::Int.optional
      attribute :owner, Account
      attribute :origin_id, Types::Strict::String
      attribute :title, Types::Strict::String
      attribute :pages, Types::Strict::Array.member(Page)
    end
  end
end
