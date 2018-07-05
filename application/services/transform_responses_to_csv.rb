# frozen_string_literal: true

module SurveyMoonbear
  # Return CSV format of responses
  class TransformResponsesToCSV
    def call(survey_id, launch_id)
      survey = get_survey_from_database(survey_id)
      launch = get_launch_from_database(launch_id)
      responses_hash = formatting_responses(launch.responses)
      headers_arr = build_responses_table_header(survey)
      responses_arr = build_responses_arr(responses_hash, headers_arr)
      transform_to_csv(responses_arr)
    end

    def get_survey_from_database(survey_id)
      Repository::For[Entity::Survey].find_id(survey_id)
    end

    def get_launch_from_database(launch_id)
      Repository::For[Entity::Launch].find_id(launch_id)
    end

    def formatting_responses(responses)
      responses_hash = {}
      responses.each do |r|
        if responses_hash[r.respondent_id.to_s].nil?
          responses_hash[r.respondent_id.to_s] = [r.response]
        else
          responses_hash[r.respondent_id.to_s].push(r.response)
        end
      end

      responses_hash
    end

    def build_responses_table_header(survey)
      headers_arr = ['respondent']
      survey.pages.each do |page|
        page.items.each do |item|
          if item.type != 'Description' && item.type != 'Section Title'
            headers_arr.push(item.name)
          end
        end
      end
      headers_arr.push('start_time', 'end_time', 'url_params')

      headers_arr
    end

    def build_responses_arr(responses_hash, headers_arr)
      responses_arr = responses_hash.map do |key, value|
        [key, value].flatten
      end

      responses_arr.unshift(headers_arr)
    end

    def transform_to_csv(responses_arr)
      csv_string = CSV.generate do |csv|
        responses_arr.each do |data|
          csv << data
        end
      end

      csv_string
    end
  end
end
