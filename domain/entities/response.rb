# frozen_string_literal: true

require 'dry-struct'

module SurveyMoonbear
  module Entity
    # Domain entity object for survey items
    class Response < Dry::Struct
      attribute :id, Types::Int.optional
      attribute :respondent_id, Types::Strict::String
      attribute :page_id, Types::Int
      attribute :item_id, Types::Int
      attribute :response, Types::Strict::String.optional
      attribute :item_type, Types::Strict::String
      attribute :item_name, Types::Strict::String
      attribute :item_description, Types::Strict::String
      attribute :item_required, Types::Strict::Int
      attribute :item_options, Types::Strict::String.optional
    end
  end
end
