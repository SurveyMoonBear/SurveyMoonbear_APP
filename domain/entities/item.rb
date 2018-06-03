# frozen_string_literal: true

require 'dry-struct'

module SurveyMoonbear
  module Entity
    # Domain entity object for survey items
    class Item < Dry::Struct
      attribute :id, Types::Int.optional
      attribute :type, Types::Strict::String
      attribute :name, Types::Strict::String
      attribute :description, Types::Strict::String
      attribute :required, Types::Strict::Int
      attribute :options, Types::Strict::String.optional
    end
  end
end
