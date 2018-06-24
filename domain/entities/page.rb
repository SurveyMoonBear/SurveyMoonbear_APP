# frozen_string_literal: true

require 'dry-struct'

require_relative 'item.rb'

module SurveyMoonbear
  module Entity
    # Domain entity object for survey pages
    class Page < Dry::Struct
      attribute :id, Types::Int.optional
      attribute :title, Types::Strict::String
      attribute :index, Types::Strict::Int
      attribute :items, Types::Strict::Array.member(Item).optional
    end
  end
end
