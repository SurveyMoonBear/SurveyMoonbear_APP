# frozen_string_literal: true

require_relative 'study'
require_relative 'survey'

module SurveyMoonbear
  module Entity
    # Domain entity object for any notification
    class Notification < Dry::Struct
      include Dry.Types
      attribute :id, Integer.optional
      attribute :owner, Account
      attribute :study, Study
      attribute :survey, Survey
      attribute :type, Strict::String
      attribute :title, Strict::String
      attribute :fixed_timestamp, Strict::Time.optional
      attribute :content, Strict::String
      attribute :repeat_at, Strict::String.optional
      attribute :repeat_set_time, Strict::String.optional
      attribute :repeat_random_every, Strict::String.optional
      attribute :repeat_random_start, Strict::String.optional
      attribute :repeat_random_end, Strict::String.optional
      attribute :created_at, Strict::Time.optional
    end
  end
end
