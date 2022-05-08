# frozen_string_literal: true

require_relative 'study'

module SurveyMoonbear
  module Entity
    # Domain entity object for any participant
    class Participant < Dry::Struct
      include Dry.Types
      attribute :id, String.optional
      attribute :owner, Account
      attribute :study, Study
      attribute :details, Strict::String.optional
      attribute :nickname, Strict::String
      attribute :contact_type, Strict::String
      attribute :email, Strict::String
      attribute :phone, Strict::String.optional
      attribute :aws_arn, Strict::String.optional
      attribute :status, Strict::String
      attribute :created_at, Strict::Time.optional
    end
  end
end
