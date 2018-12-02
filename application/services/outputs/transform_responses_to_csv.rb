# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return CSV format of responses
    # Usage: Service::TransformResponsesToCSV.new.call(survey_id: "...", launch_id: "...")
    class TransformResponsesToCSV
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database
      step :get_launch_from_database
      step :formatting_responses
      step :build_responses_table_headers
      step :build_responses_arr
      step :transform_to_csv

      private

      # input {survey_id:, launch_id:}
      def get_survey_from_database(input)
        input[:survey] = Repository::For[Entity::Survey].find_id(input[:survey_id])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get survey from database')
      end

      # input {survey_id:, launch_id:, survey:}
      def get_launch_from_database(input)
        launch = Repository::For[Entity::Launch].find_id(input[:launch_id])

        input[:responses] = launch.responses
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get launch from database')
      end

      # input {survey_id:, launch_id:, survey:, responses:}
      def formatting_responses(input)
        responses_hash = {}
        input[:responses].each do |r|
          if responses_hash[r.respondent_id.to_s].nil?
            responses_hash[r.respondent_id.to_s] = [r.response]
          else
            responses_hash[r.respondent_id.to_s].push(r.response)
          end
        end

        input[:responses_hash] = responses_hash
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to formatting responses')
      end

      # input {survey_id:, launch_id:, survey:, responses:, responses_hash:}
      def build_responses_table_headers(input)
        headers_arr = ['respondent']
        input[:survey].pages.each do |page|
          page.items.each do |item|
            if item.type != 'Description' && item.type != 'Section Title' && item.type != 'Divider'
              headers_arr.push(item.name)
            end
          end
        end
        headers_arr.push('start_time', 'end_time', 'url_params')

        input[:headers_arr] = headers_arr
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to build responses table headers')
      end

      # input {survey_id:, launch_id:, survey:, responses:, responses_hash:, headers_arr:}
      def build_responses_arr(input)
        input[:responses_arr] = input[:responses_hash].map do |key, value|
          [key, value].flatten
        end
        
        input[:responses_arr].unshift(input[:headers_arr])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to build responses array for csv transformation')
      end

      # input {survey_id:, launch_id:, survey:, responses:, responses_hash:, headers_arr:, responses_arr:}
      def transform_to_csv(input)
        csv_string = CSV.generate do |csv|
          input[:responses_arr].each do |data|
            csv << data
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
