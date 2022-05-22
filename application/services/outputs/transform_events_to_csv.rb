# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return CSV format of responses
    # Usage: Service::TransformEventsToCSV.new.call(study_id: "...", participant_id: "...")
    class TransformEventsToCSV
      include Dry::Transaction
      include Dry::Monads

      step :get_participant_list # all participants or specific participant
      step :build_table_headers # participant_id, nickname, start_at, end_at
      step :parse_event_data
      step :transform_to_csv

      private

      # input { study_id:, type:, participant_id: }
      def get_participant_list(input)
        input[:list] = if input[:participant_id].empty?
                         Repository::For[Entity::Participant].find_study(input[:study_id])
                       else
                         [Repository::For[Entity::Participant].find_id(input[:participant_id])]
                       end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get requested participants list from db.')
      end

      # input { study_id:, type:, participant_id:, list: }
      def build_table_headers(input)
        input[:headers_arr] = %w[participant_id nickname start_at end_at]
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to build events data table headers.')
      end

      # input { study_id:, type:, participant_id:, list: }
      def parse_event_data(input)
        input[:rows_arr] = []
        input[:list].each do |participant|
          events = Repository::For[Entity::Event].find_participant(participant.id)
          events.each do |event|
            input[:rows_arr] << [participant.id, participant.nickname, event.start_at, event.end_at]
          end
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to parse events data from db.')
      end

      # input { ..., rows_arr: }
      def transform_to_csv(input)
        csv_string = CSV.generate do |csv|
          csv << input[:headers_arr]

          input[:rows_arr].each do |row|
            csv << row
          end
        end

        Success(csv_string)
      rescue StandardError => e
        puts e
        Failure('Failed to transform responses array to csv')
      end
    end
  end
end
