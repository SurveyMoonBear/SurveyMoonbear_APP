# frozen_string_literal: true

require 'json'

module SurveyMoonbear
  # Return nil
  class StoreResponses
    def initialize(survey_id, launch_id)
      @survey_id = survey_id
      @launch_id = launch_id
    end

    def call(respondent_id, responses)
      arr_responses = create_responses_arr(respondent_id, responses)
      store_into_database(arr_responses)
    end

    def create_responses_arr(respondent_id, responses)
      pages = fetch_survey_items
      arr_responses = []
      pages.each do |page|
        page_index = page.index
        page.items.each do |item|
          next if item.type == 'Description' || item.type == 'Section Title' || item.type == 'Divider'
          new_response = create_response_entity(page_index,
                                                item,
                                                respondent_id,
                                                responses[item.name])
          arr_responses.push(new_response)
          responses.delete(item.name)
        end
      end
      page_index_for_other_data = pages.length
      time_records = store_time_params(respondent_id, responses, page_index_for_other_data)
      time_records.each { |record| arr_responses.push(record) }
      arr_responses.push(store_url_params(respondent_id, responses, page_index_for_other_data))
    end

    def fetch_survey_items
      survey = Repository::For[Entity::Survey].find_id(@survey_id)
      survey.pages
    end

    def create_response_entity(page_index, item, respondent_id, response)
      item_json = JSON.generate(type: item.type,
                                name: item.name,
                                description: item.description,
                                required: item.required,
                                options: item.options)

      Entity::Response.new(
        id: nil,
        respondent_id: respondent_id,
        page_index: page_index,
        item_order: item.order,
        response: response,
        item_data: item_json
      )
    end

    def store_time_params(respondent_id, responses, page_index)
      start_time = Entity::Response.new(id: nil,
                                        respondent_id: respondent_id,
                                        page_index: page_index,
                                        item_order: 0,
                                        response: responses['moonbear_start_time'],
                                        item_data: nil)
      end_time = Entity::Response.new(id: nil,
                                      respondent_id: respondent_id,
                                      page_index: page_index,
                                      item_order: 1,
                                      response: responses['moonbear_end_time'],
                                      item_data: nil)
      responses.delete('moonbear_start_time')
      responses.delete('moonbear_end_time')
      [start_time, end_time]
    end

    def store_url_params(respondent_id, responses, page_index)
      return nil if responses['moonbear_url_params'].nil?
      Entity::Response.new(id: nil,
                           respondent_id: respondent_id,
                           page_index: page_index,
                           item_order: 2,
                           response: responses['moonbear_url_params'],
                           item_data: nil)
    end

    def store_into_database(new_responses)
      Repository::For[Entity::Launch].add_multi_responses(@launch_id, new_responses)
    end
  end
end
