# frozen_string_literal: true

module SurveyMoonbear
  module Entity
    # Domain entity object for visual report sources
    class Source < Dry::Struct
      include Dry.Types
      attribute :source_type, Strict::String
      attribute :source_name, Strict::String
      attribute :source_id, Strict::String
      attribute :case_id, Strict::String.optional
    end
  end
end
