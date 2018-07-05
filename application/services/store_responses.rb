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
      pages = fetch_survey_items
      pages.each do |page|
        page_id = page.id
        page.items.each do |item|
          next if item.type == 'Description' || item.type == 'Section Title' || item.type == 'Divider'
          new_response = create_response_entity(page_id,
                                                item,
                                                respondent_id,
                                                responses[item.name])
          store_into_database(new_response)
          responses.delete(item.name)
        end
      end
      store_time_params(respondent_id, responses)
      store_url_params(respondent_id, responses)
    end

    def fetch_survey_items
      survey = Repository::For[Entity::Survey].find_id(@survey_id)
      survey.pages
    end

    def create_response_entity(page_id, item, respondent_id, response)
      item_json = JSON.generate(type: item.type,
                                name: item.name,
                                description: item.description,
                                required: item.required,
                                options: item.options)

      Entity::Response.new(
        id: nil,
        respondent_id: respondent_id,
        page_id: page_id,
        item_id: item.id,
        response: response,
        item_data: item_json
      )
    end

    def store_into_database(new_response)
      Repository::For[Entity::Launch].add_response(@launch_id, new_response)
    end

    def store_time_params(respondent_id, responses)
      start_time = Entity::Response.new(id: nil,
                                        respondent_id: respondent_id,
                                        page_id: 0,
                                        item_id: 'moonbear_start_time',
                                        response: responses['moonbear_start_time'],
                                        item_data: nil)
      store_into_database(start_time)
      end_time = Entity::Response.new(id: nil,
                                      respondent_id: respondent_id,
                                      page_id: 0,
                                      item_id: 'moonbear_end_time',
                                      response: responses['moonbear_end_time'],
                                      item_data: nil)
      store_into_database(end_time)
      responses.delete('moonbear_start_time')
      responses.delete('moonbear_end_time')
    end

    def store_url_params(respondent_id, responses)
      responses.each do |key, _|
        if key.include?('radio') || key.include?('checkbox')
          responses.delete(key)
        end
      end

      return nil if responses['moonbear_url_params'].nil?
      new_response = Entity::Response.new(id: nil,
                                          respondent_id: respondent_id,
                                          page_id: 0,
                                          item_id: 'url_params',
                                          response: responses['moonbear_url_params'],
                                          item_data: nil)
      store_into_database(new_response)
    end
  end
end
