# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::CheckCalendarInList.new.call(config: <config>, current_account: {}, participant_id:, calendar_id:)
    class CheckCalendarInList
      include Dry::Transaction
      include Dry::Monads

      step :refresh_user_access_token
      step :check_calendar_in_list
      step :update_participant_act_status

      private

      # input { config:, current_account:, participant_id:, calendar_id: }
      def refresh_user_access_token(input)
        input[:participant] = Repository::For[Entity::Participant].find_id(input[:participant_id])
        refresh_token = input[:participant].owner.refresh_token
        input[:user_access_token] = Google::Auth.new(input[:config]).refresh_user_access_token(refresh_token)
        Success(input)
      rescue
        Failure('Failed to refresh Google API access token.')
      end

      def check_calendar_in_list(input)
        input[:check] = Google::Api::Calendar.new(input[:user_access_token])
                                             .calendar_in_list?(input[:calendar_id])
        Success(input)
      rescue
        Failure('Failed to check participant calendar.')
      end

      # input { ... }
      def update_participant_act_status(input)
        unless input[:check]
          UpdateParticipant.new.call(participant_id: input[:participant_id],
                                     params: { act_status: 'unsubscribed' })
        end
        Success(input[:check])
      rescue
        Failure('Failed to update participant calendar status into database.')
      end
    end
  end
end
