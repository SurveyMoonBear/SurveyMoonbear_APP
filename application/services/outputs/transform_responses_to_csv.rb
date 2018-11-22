# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # Return CSV format of responses
  # Usage: TransformResponsesToCSV.new.call(survey_id: "...", launch_id: "...")
  class TransformResponsesToCSV
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :get_launch_from_database
    step :formatting_responses
    step :build_responses_table_headers
    step :build_responses_arr
    step :transform_to_csv

    def get_survey_from_database(survey_id:, launch_id:)
      survey = Repository::For[Entity::Survey].find_id(survey_id)
      Success(survey: survey, launch_id: launch_id)
    rescue
      Failure('Failed to get survey from database')
    end

    def get_launch_from_database(survey:, launch_id:)
      launch = Repository::For[Entity::Launch].find_id(launch_id)
      Success(responses: launch.responses, survey: survey)
    rescue
      Failure('Failed to get launch from database')
    end

    def formatting_responses(responses:, survey:)
      responses_hash = {}
      responses.each do |r|
        if responses_hash[r.respondent_id.to_s].nil?
          responses_hash[r.respondent_id.to_s] = [r.response]
        else
          responses_hash[r.respondent_id.to_s].push(r.response)
        end
      end
      Success(responses_hash: responses_hash, survey: survey)
    rescue
      Failure('Failed to formatting responses')
    end

    def build_responses_table_headers(responses_hash:, survey:)
      headers_arr = ['respondent']
      survey.pages.each do |page|
        page.items.each do |item|
          if item.type != 'Description' && item.type != 'Section Title' && item.type != 'Divider'
            headers_arr.push(item.name)
          end
        end
      end
      headers_arr.push('start_time', 'end_time', 'url_params')
      Success(headers_arr: headers_arr, responses_hash: responses_hash)
    rescue
      Failure('Failed to build responses table headers')
    end

    def build_responses_arr(headers_arr:, responses_hash:)
      responses_arr = responses_hash.map do |key, value|
        [key, value].flatten
      end
      responses_arr.unshift(headers_arr)
      Success(responses_arr: responses_arr)
    rescue
      Failure('Failed to build responses array for csv transformation')
    end

    def transform_to_csv(responses_arr:)
      csv_string = CSV.generate do |csv|
        responses_arr.each do |data|
          csv << data
        end
      end
      Success(csv_string)
    rescue
      Failure('Failed to transform responses array to csv')
    end
  end
end
