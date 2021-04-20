# frozen_string_literal: true

module SurveyMoonbear
  module Entity
    # Domain entity object for survey items
    class Response < Dry::Struct
      include Dry.Types
      attribute :id, Integer.optional
      attribute :respondent_id, Strict::String
      attribute :page_index, Integer
      attribute :item_order, Integer
      attribute :response, Strict::String.optional
      attribute :item_data, Strict::String.optional
    end
  end
end
