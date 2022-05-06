# frozen_string_literal: true

require_relative 'study_mapper'
require_relative '../google_mappers/account_mapper'
require 'time'

module SurveyMoonbear
  module Mapper
    # Data Mapper object for Google's spreadsheet
    class ParticipantMapper
      def load(data)
        participant = {}
        participant[:data] = data[:params]
        participant[:study] = data[:study]
        participant[:owner] = data[:current_account]
        build_entity(participant)
      end

      def build_entity(participant)
        DataMapper.new(participant).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(participant)
          @participant = participant
          @account_mapper = Google::AccountMapper.new
        end

        def build_entity
          SurveyMoonbear::Entity::Participant.new(
            id: nil,
            owner: owner,
            study: study,
            details: details,
            nickname: nickname,
            contact_type: contact_type,
            email: email,
            phone: phone,
            aws_arn: aws_arn,
            status: status,
            created_at: nil
          )
        end

        def owner
          @account_mapper.load(@participant[:owner])
        end

        def study
          @participant[:study]
        end

        def details
          @participant[:data]['details']
        end

        def nickname
          @participant[:data]['nickname']
        end

        def contact_type
          @participant[:data]['contact_type']
        end

        def email
          @participant[:data]['email']
        end

        def phone
          @participant[:data]['phone']
        end

        def aws_arn
          @participant[:data]['aws_arn']
        end

        def status
          @participant[:data]['status']
        end
      end
    end
  end
end
