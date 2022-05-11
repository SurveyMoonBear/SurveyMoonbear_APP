# frozen_string_literal: true

require_relative 'account_mapper'
require_relative '../mappers/participant_mapper'

module SurveyMoonbear
  module Google
    # Data Mapper object for Google's calendar
    class EventMapper
      def initialize(gateway)
        @gateway = gateway
      end

      def load(calendar_id, owner)
        event = {}
        event[:data] = @gateway.event_data(calendar_id)
        event[:owner] = owner
        build_entity(event)
      end

      def build_entity(event)
        DataMapper.new(event, @gateway).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(event)
          # def initialize(event, gateway)
          @event = event
          @account_mapper = AccountMapper.new
          @participant_mapper = ParticipantMapper.new
        end

        def build_entity
          EventMoonbear::Entity::Event.new(
            id: nil,
            owner: owner,
            participant: nil,
            origin_id: origin_id,
            start_at: start_at,
            end_at: end_at,
            time_zone: time_zone
          )
        end

        def owner
          @account_mapper.load(@event[:owner])
        end

        def participant
          @participant_mapper.load(@event[:participant])
        end

        def origin_id
          @event[:data]['calendarId']
        end

        def start_at
          @event[:data]['properties']['title']
        end

        def end_at
          @event[:data]['properties']['title']
        end

        def time_zone
          @event[:data]['properties']['title']
        end
      end
    end
  end
end
