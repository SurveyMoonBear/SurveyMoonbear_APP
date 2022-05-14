# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::RefreshEvents.new.call(config: <config>, current_account: {}, participant_id:)
    class RefreshEvents
      include Dry::Transaction
      include Dry::Monads

      step :refresh_user_access_token
      step :check_calendar_in_list
      step :get_events_data_from_google
      step :delete_archive_events_from_db
      step :store_new_events_into_db

      private

      # input { config:, current_account:, participant_id: }
      def refresh_user_access_token(input)
        input[:participant] = Repository::For[Entity::Participant].find_id(input[:participant_id])
        refresh_token = input[:participant].owner.refresh_token
        input[:user_access_token] = Google::Auth.new(input[:config]).refresh_user_access_token(refresh_token)
        input[:study] = Repository::For[Entity::Study].find_id(input[:participant].study.id)
        Success(input)
      rescue
        Failure('Failed to refresh Google API user access token.')
      end

      def check_calendar_in_list(input)
        check = CheckCalendarInList.new.call(config: input[:config],
                                             calendar_id: input[:participant].email,
                                             current_account: input[:current_account],
                                             participant_id: input[:participant_id])
        if check.value!
          Success(input)
        else
          Failure('Calendar is out of list')
        end
      rescue
        Failure('Failed to check calender in list or not.')
      end

      # input { ... }
      def get_events_data_from_google(input)
        input[:events] = Google::Api::Calendar.new(input[:user_access_token])
                                              .events_data(input[:participant].email,
                                                           input[:study].activity_start_at,
                                                           input[:study].activity_end_at)
        Success(input)
      rescue
        Failure('Failed to get events data from Google Calendar.')
      end

      # input { ... }
      def delete_archive_events_from_db(input)
        original_events = Repository::For[Entity::Event].find_participant(input[:participant_id])
        Repository::For[Entity::Event].delete_all(original_events)

        Success(input)
      rescue
        Failure('Failed to delete archive events from database.')
      end

      # input { ... }
      def store_new_events_into_db(input)
        new_events = input[:events].map do |event|
          new_event = Google::EventMapper.new.load(event, input[:participant], input[:current_account])
          Repository::For[new_event.class].find_or_create(new_event)
        end
        Success(new_events)
      rescue
        Failure('Failed to store new events into database.')
      end
    end
  end
end
