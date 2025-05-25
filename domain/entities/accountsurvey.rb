# frozen_string_literal: false

module SurveyMoonbear
  module Entity
    # Domain entity object for any google account
    class AccountSurvey  < Dry::Struct
      include Dry.Types
      attribute :owner_id,   Integer
      attribute :survey_id,  String 
      attribute :role,       String
      attribute :created_at, Time.optional
      attribute :updated_at, Time.optional
    end
  end
end
