# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return CSV format of responses
    # Usage: Service::TransformParticipantsToCSV.new.call(study_id: "...", participant_id: "...")
    class TransformParticipantsToCSV
      include Dry::Transaction
      include Dry::Monads

      step :get_participant_list # all participants or specific participant
      step :build_table_headers
      step :parse_info_data # participant_id, nickname, contact_type, email, phone,
      step :parse_details_data # depends on {all participants -> string}, {specific participant -> column}
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
        input[:headers_arr] = %w[participant_id nickname contact_type email phone]
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get requested participants list from db.')
      end

      # input { study_id:, type:, participant_id:, list: }
      def parse_info_data(input)
        input[:rows_arr] = []
        input[:list].each do |ptcp|
          input[:rows_arr] << [ptcp.id, ptcp.nickname, ptcp.contact_type, ptcp.email, ptcp.phone]
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get requested participants list from db.')
      end

      # input { study_id:, type:, participant_id:, list: }
      def parse_details_data(input)
        if input[:list].length == 1 && !input[:list][0].details.empty?
          hash = JSON.parse(input[:list][0].details)
          hash.each_key { |k| input[:headers_arr] << k.to_s }
          hash.each_value { |v| input[:rows_arr][0] << v.to_s }
        else
          input[:headers_arr] << 'details'
          input[:rows_arr].each_with_index do |row, idx|
            row << input[:list][idx].details.to_s
          end
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get requested participants list from db.')
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
