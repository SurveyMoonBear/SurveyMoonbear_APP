# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::SubscribeAllCalendars.new.call(config: <config>, current_account: {}, study_id:)
    class SubscribeAllCalendars
      include Dry::Transaction
      include Dry::Monads

      step :get_all_participants
      step :subscribe_all_calendars

      private

      # input { config:, current_account:, study_id: }
      def get_all_participants(input)
        input[:participants] = Repository::For[Entity::Participant].find_study(input[:study_id])
        Success(input)
      rescue
        Failure('Failed to get all participants.')
      end

      # input { ... }
      def subscribe_all_calendars(input)
        input[:participants].map do |participant|
          next if participant.act_status == 'subscribe'

          SubscribeCalendar.new.call(config: input[:config],
                                     current_account: input[:current_account],
                                     participant_id: participant.id,
                                     calendar_id: participant.email)
        end
        Success(input)
      rescue
        Failure('Failed to unsubscribe participant calendar.')
      end
    end
  end
end
