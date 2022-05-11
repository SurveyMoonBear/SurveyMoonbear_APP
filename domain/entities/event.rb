# frozen_string_literal: true

require_relative 'study'
require_relative 'participant'

module SurveyMoonbear
  module Entity
    # Domain entity object for any event
    class Event < Dry::Struct
      include Dry.Types
      attribute :id, Integer.optional
      attribute :owner, Account
      attribute :participant, Participant
      attribute :origin_id, Strict::String
      attribute :start_at, Strict::Time
      attribute :end_at, Strict::Time
      attribute :time_zone, Strict::String.optional
      attribute :created_at, Strict::Time.optional
      attribute :updated_at, Strict::Time.optional
    end
  end
end
