# frozen_string_literal: true

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
      'store responses!'
    end

    def fetch_survey_items
      @survey = Database::SurveyOrm.where(origin_id: @survey_id).first
      @survey.pages
    end

    def create_response_entity(page_id, item, responses)
      puts item.name
      puts responses[:responses]['age_num']
      Entity::Response.new(
        id: nil,
        respondent_id: responses[:respondent_id],
        page_id: page_id,
        item_id: item.id,
        response: responses[:responses][item.name],
        item_type: item.type,
        item_name: item.name,
        item_description: item.description,
        item_required: item.required,
        item_options: item. options
      )
    end

    def store_into_database(new_response)
      Repository::For[Entity::Survey].add_response(@survey, new_response)
    end
  end
end
