# frozen_string_literal: true

require 'dry/transaction'
require 'json'

module SurveyMoonbear
  module Service
    # Return an array of events and summary
    # Usage: Service::GetEvents.new.call(participant_id: "...")
    class GetEvents
      include Dry::Transaction
      include Dry::Monads

      step :get_events
      step :count_busy_time

      private

      def sec_to_hms(sec)
        '%02d:%02d:%02d' % [sec / 3600, sec / 60 % 60, sec % 60]
      end

      # input { participant_id: }
      def get_events(input)
        input[:events] = Repository::For[Entity::Event].find_participant(input[:participant_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get participant from database.')
      end

      # input { participant_id: , events: }
      def count_busy_time(input)
        sec = input[:events].reduce(0) { |time, event| time + (event.end_at - event.start_at) }
        input[:busy_time] = sec_to_hms(sec)
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get participant arn from database.')
      end
    end
  end
end
