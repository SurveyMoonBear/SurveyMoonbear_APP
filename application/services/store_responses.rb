# frozen_string_literal: true

require 'json'

module SurveyMoonbear
  # Return nil
  class StoreResponses
    def initialize(survey_id)
      @survey_id = survey_id
    end

    def call(responses)
      pages = fetch_survey_items
      pages.each do |page|
        page_id = page.id
        page.items.each do |item|
          if item.type != 'Description' && item.type != 'Section Title'
            new_response = create_response_entity(page_id, item, responses)
            store_into_database(new_response)
          end
        end
      end
    end

    def fetch_survey_items
      @survey = Database::SurveyOrm.where(origin_id: @survey_id).first
      @survey.pages
    end

    def create_response_entity(page_id, item, responses)
      item_json = JSON.generate(type: item.type,
                                name: item.name,
                                description: item.description,
                                required: item.required,
                                options: item.options)
      puts item_json

      Entity::Response.new(
        id: nil,
        respondent_id: responses[:respondent_id],
        page_id: page_id,
        item_id: item.id,
        response: responses[:responses][item.name],
        item_data: item_json
      )
    end

    def store_into_database(new_response)
      Repository::For[Entity::Survey].add_response(@survey, new_response)
    end
  end
end
