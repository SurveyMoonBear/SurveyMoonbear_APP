# frozen_string_literal: true

require 'dry-struct'

require_relative 'page.rb'
require_relative 'response.rb'

module SurveyMoonbear
  module Entity
    # Domain entity object for any survey
    class Survey < Dry::Struct
      attribute :id, Types::Int.optional
      attribute :owner, Account
      attribute :origin_id, Types::Strict::String
      attribute :title, Types::Strict::String
      attribute :start_flag, Types::Strict::Bool.optional
      attribute :pages, Types::Strict::Array.member(Page)
      attribute :responses, Types::Strict::Array.member(Response).optional
    end
  end
end
