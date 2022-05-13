# frozen_string_literal: true

require_relative 'account_mapper'

module SurveyMoonbear
  module Google
    # Data Mapper object for Google's calendar
    class EventMapper
      def load(data, participant, owner)
        event = {}
        event[:data] = data
        event[:participant] = participant
        event[:owner] = owner
        build_entity(event)
      end

      def build_entity(event)
        DataMapper.new(event).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(event)
          @event = event
          @account_mapper = AccountMapper.new
        end

        def build_entity
          SurveyMoonbear::Entity::Event.new(
            id: nil,
            owner: owner,
            participant: participant,
            start_at: start_at,
            end_at: end_at,
            # time_zone: time_zone,
            created_at: nil,
            updated_at: nil
          )
        end

        def owner
          @account_mapper.load(@event[:owner])
        end

        def participant
          @event[:participant]
        end

        def start_at
          Time.parse(@event[:data]['start'])
        end

        def end_at
          Time.parse(@event[:data]['end'])
        end

        # def time_zone
        #   @event[:data]['start']['timeZone']
        # end
      end
    end
  end
end
