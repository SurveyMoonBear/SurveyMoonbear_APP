# frozen_string_literal: true

require 'dry/transaction'
require 'json'

module SurveyMoonbear
  module Service
    # Return a deleted participant
    # Usage: Service::GetParticipant.new.call(participant_id: "...")
    class GetParticipant
      include Dry::Transaction
      include Dry::Monads

      step :get_participant
      step :get_participant_details

      private

      # input { participant_id: }
      def get_participant(input)
        input[:participant] = Repository::For[Entity::Participant].find_id(input[:participant_id])

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get participant from database.')
      end

      # input { participant_id: , participant: }
      def get_participant_details(input)
        input[:details] = if input[:participant].details.empty?
                            input[:participant].details
                          else
                            modified_string = input[:participant][:details]
                                              .gsub(/:(\w+)/) { "\"#{$1}\"" }
                                              .gsub('=>', ':')
                                              .gsub('nil', 'null')

                            JSON.parse(modified_string)
                          end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get participant details from database.')
      end
    end
  end
end
