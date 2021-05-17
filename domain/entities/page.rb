# frozen_string_literal: true

require_relative 'item'

module SurveyMoonbear
  module Entity
    # Domain entity object for survey pages
    class Page < Dry::Struct
      include Dry.Types
      attribute :id, Integer.optional
      attribute :title, Strict::String
      attribute :index, Strict::Integer
      attribute :items, Strict::Array.of(Item).optional
    end
  end
end
