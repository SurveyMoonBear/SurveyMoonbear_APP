# frozen_string_literal: true

module SurveyMoonbear
  module Entity
    # Domain entity object for survey items
    class Item < Dry::Struct
      include Dry.Types
      attribute :id, Integer.optional
      attribute :order, Integer
      attribute :type, Strict::String
      attribute :name, String
      attribute :description, String
      attribute :required, Strict::Integer
      attribute :options, Strict::String.optional
    end
  end
end
