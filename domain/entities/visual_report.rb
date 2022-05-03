# frozen_string_literal: true

module SurveyMoonbear
  module Entity
    # Domain entity object for any visual_report
    class VisualReport < Dry::Struct
      include Dry.Types
      attribute :id, String.optional
      attribute :owner, Account
      attribute :origin_id, Strict::String
      attribute :title, Strict::String
      attribute :created_at, Strict::Time.optional
    end
  end
end
