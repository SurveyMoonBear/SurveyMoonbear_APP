# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return CSV format of responses
    # Usage: Service::TransformResponsesToCSV.new.call(launch_id: "...")
    class TransformResponsesToCSV
      include Dry::Transaction
      include Dry::Monads

      # Item orders of additional data in the last page
      START_TIME_ITEM_ORDER = 0
      END_TIME_ITEM_ORDER = 1
      URL_PARAMS_ITEM_ORDER = 2

      step :get_launch_from_database
      step :organize_responses_to_hash_array_of_respondent_responses_pairs
      step :sort_responses_by_item_name
      step :build_response_table_headers
      step :build_response_rows_arr
      step :filter_participant
      step :transform_to_csv

      private

      # input { launch_id: }
      def get_launch_from_database(input)
        launch = Repository::For[Entity::Launch].find_id(input[:launch_id])

        input[:response_objs] = launch.responses
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get launch from database')
      end

      # input { ..., response_objs: }
      def organize_responses_to_hash_array_of_respondent_responses_pairs(input)
        response_hashes = {}

        input[:response_objs].each do |res_obj|
          respondent_id = res_obj.respondent_id
          response_hashes[respondent_id] = {} if response_hashes[respondent_id].nil?

          # Use item_data of responses to build hash-array: [{ respondent_id => {item_name=>response, ...} }, ... ]
          if !res_obj.item_data.nil?
            item_name = JSON.parse(res_obj.item_data)['name']
            response_hashes[respondent_id][item_name] = res_obj.response
          else  # Additional data's item_data column is nil
            case res_obj.item_order
            when START_TIME_ITEM_ORDER
              response_hashes[respondent_id]['start_time'] = res_obj.response
            when END_TIME_ITEM_ORDER
              response_hashes[respondent_id]['end_time'] = res_obj.response
            when URL_PARAMS_ITEM_ORDER
              response_hashes[respondent_id]['url_params'] = res_obj.response
            end
          end
        end

        input[:response_hashes] = response_hashes
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to organize responses to hash array of respondent-responses.')
      end

      # input { ..., response_hashes: }
      def sort_responses_by_item_name(input)
        input[:sorted_response_hashes] = input[:response_hashes].map do |respondent, item_name|
          sorted_res_hash = { respondent => item_name.sort().to_h }

          # Move additional data to the last elements of the hash
          sorted_res_hash[respondent]['start_time'] = sorted_res_hash[respondent].delete('start_time')
          sorted_res_hash[respondent]['end_time'] = sorted_res_hash[respondent].delete('end_time')
          sorted_res_hash[respondent]['url_params'] = sorted_res_hash[respondent].delete('url_params')

          sorted_res_hash
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to sort responses by item name.')
      end

      # input { ..., sorted_response_hashes: }
      def build_response_table_headers(input)
        response_table_headers = input[:sorted_response_hashes][0].values[0].keys

        input[:headers_arr] = response_table_headers
        input[:headers_arr].unshift('respondent')
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to build responses table headers.')
      end

      # input { ..., headers_arr: }
      def build_response_rows_arr(input)
        input[:rows_arr] = input[:sorted_response_hashes].map do |hash|
          res_row = []
          hash.each do |respondent_id, responses_hash|
            res_row = responses_hash.values
            res_row.unshift(respondent_id)
          end
          res_row
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to build response rows array.')
      end

      def filter_participant(input)
        unless input[:participant_id].nil? || input[:participant_id].empty?
          rows_arr = []
          input[:rows_arr].each do |row|
            rows_arr << row if row.include?("{\"p\":\"#{input[:participant_id]}\"}")
          end
          input[:rows_arr] = rows_arr
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to filter participant in rows array.')
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
