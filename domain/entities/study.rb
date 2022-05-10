# frozen_string_literal: true

require_relative 'survey'

module SurveyMoonbear
  module Entity
    # Domain entity object for any study
    class Study < Dry::Struct
      include Dry.Types
      attribute :id, String.optional
      attribute :owner, Account
      attribute :title, Strict::String
      attribute :desc, Strict::String.optional
      attribute :state, Strict::String.optional
      attribute :enable_notification, Strict::Bool
      attribute :aws_arn, Strict::String.optional
      attribute :track_activity, Strict::Bool
      attribute :activity_start_at, Strict::Time.optional
      attribute :activity_end_at, Strict::Time.optional
      attribute :including_surveys, Strict::Array.of(Survey).optional
      attribute :created_at, Strict::Time.optional
    end
  end
end
