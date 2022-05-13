# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::SubscribeCalendar.new.call(config: <config>, current_account: {}, participant_id:, calendar_id:)
    class SubscribeCalendar
      include Dry::Transaction
      include Dry::Monads

      step :refresh_user_access_token
      step :subscribe_calendar
      step :update_participant_act_status
      step :refresh_events

      private

      # input { config:, current_account:, participant_id:, calendar_id: }
      def refresh_user_access_token(input)
        participant = Repository::For[Entity::Participant].find_id(input[:participant_id])
        refresh_token = participant.owner.refresh_token
        input[:user_access_token] = Google::Auth.new(input[:config]).refresh_user_access_token(refresh_token)
        Success(input)
      rescue
        Failure('Failed to refresh Google API access token.')
      end

      # input { ... }
      def subscribe_calendar(input)
        Google::Api::Calendar.new(input[:user_access_token])
                             .subscribe_calendar(input[:calendar_id])
        Success(input)
      rescue
        Failure('Failed to subscribe participant calendar.')
      end

      # input { ... }
      def update_participant_act_status(input)
        UpdateParticipant.new.call(participant_id: input[:participant_id],
                                   params: { act_status: 'subscribed' })
        Success(input)
      rescue
        Failure('Failed to update participant calendar status into database.')
      end

      def refresh_events(input)
        new_events = RefreshEvents.new.call(config: input[:config],
                                            current_account: input[:current_account],
                                            participant_id: input[:participant_id])
        Success(new_events)
      rescue
        Failure('Failed to refresh participant events into database.')
      end
    end
  end
end
