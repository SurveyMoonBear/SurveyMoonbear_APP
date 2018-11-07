# frozen_string_literal: true

require 'dry/transaction'
require 'json'

module SurveyMoonbear
  # Return nil
  # Usage: StoreResponses.new.call(survey_id: "...", launch_id: "...", respondent_id: "...", responses: <params>)
  class StoreResponses
    include Dry::Transaction
    include Dry::Monads

    step :fetch_survey_items
    step :create_items_arr
    step :add_time_records_into_arr
    step :add_url_params_into_arr
    step :store_into_database

    def fetch_survey_items(survey_id:, launch_id:, respondent_id:, responses:)
      survey = Repository::For[Entity::Survey].find_id(survey_id)
      Success(pages: survey.pages, launch_id: launch_id, respondent_id: respondent_id, responses: responses)
    rescue
      Failure('Failed to fetch survey items with survey id.')
    end

    def create_items_arr(pages:, launch_id:, respondent_id:, responses:)
      responses_arr = []
      pages.each do |page|
        page_index = page.index
        page.items.each do |item|
          next if item.type == 'Description' || item.type == 'Section Title' || item.type == 'Divider'
          new_response = create_response_entity(page_index,
                                                item,
                                                respondent_id,
                                                responses[item.name])
          responses_arr.push(new_response)
          responses.delete(item.name)
        end
      end
      Success(responses_arr: responses_arr, page_index_for_other_data: pages.length,
              launch_id: launch_id, respondent_id: respondent_id, responses: responses)
    rescue
      Failure('Failed to create survey items array.')
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

    def add_time_records_into_arr(responses_arr:, page_index_for_other_data:, launch_id:, respondent_id:, responses:)
      start_time = Entity::Response.new(id: nil,
                                        respondent_id: respondent_id,
                                        page_index: page_index_for_other_data,
                                        item_order: 0,
                                        response: responses['moonbear_start_time'],
                                        item_data: nil)
      end_time = Entity::Response.new(id: nil,
                                      respondent_id: respondent_id,
                                      page_index: page_index_for_other_data,
                                      item_order: 1,
                                      response: responses['moonbear_end_time'],
                                      item_data: nil)
      responses.delete('moonbear_start_time')
      responses.delete('moonbear_end_time')
      time_records = [start_time, end_time]
      time_records.each { |record| responses_arr.push(record) }
      Success(responses_arr: responses_arr, page_index_for_other_data: page_index_for_other_data, 
              launch_id: launch_id, respondent_id: respondent_id, responses: responses)
    rescue
      Failure('Failed to add time records into items array.')
    end

    def add_url_params_into_arr(responses_arr:, page_index_for_other_data:, launch_id:, respondent_id:, responses:)
      unless responses['moonbear_url_params'].nil?
        url_param_item = Entity::Response.new(id: nil,
                                              respondent_id: respondent_id,
                                              page_index: page_index_for_other_data,
                                              item_order: 2,
                                              response: responses['moonbear_url_params'],
                                              item_data: nil)
        responses_arr.push(url_param_item)
      end
      Success(new_responses: responses_arr, launch_id: launch_id)
    rescue
      Failure('Failed to add url params into items array.')
    end

    def store_into_database(new_responses:, launch_id:)
      Repository::For[Entity::Launch].add_multi_responses(launch_id, new_responses)
      Success(nil)
    rescue
      Failure('Failed to store new responses into database.')
    end
  end
end
