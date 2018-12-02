# frozen_string_literal: true

require 'dry/transaction'
require 'json'

module SurveyMoonbear
  module Service
    # Return nil
    # Usage: Service::StoreResponses.new.call(survey_id: "...", launch_id: "...", respondent_id: "...", responses: <params>)
    class StoreResponses
      include Dry::Transaction
      include Dry::Monads

      step :fetch_survey_items
      step :create_items_arr
      step :add_time_records_into_arr
      step :add_url_params_into_arr
      step :store_into_database

      private

      # input {survey_id:, launch_id:, respondent_id:, responses:}
      def fetch_survey_items(input)
        survey = Repository::For[Entity::Survey].find_id(input[:survey_id])

        input[:pages] = survey.pages
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to fetch survey items with survey id.')
      end

      # input {survey_id:, launch_id:, respondent_id:, responses:, pages:}
      def create_items_arr(input)
        input[:responses_arr] = []
        
        input[:pages].each do |page|
          page_index = page.index
          page.items.each do |item|
            next if item.type == 'Description' || item.type == 'Section Title' || item.type == 'Divider'
            new_response = create_response_entity(page_index,
                                                  item,
                                                  input[:respondent_id],
                                                  input[:responses][item.name])
            input[:responses_arr].push(new_response)
            input[:responses].delete(item.name)
          end
        end

        input[:page_index_for_other_data] = input[:pages].length
        Success(input)
      rescue StandardError => e
        puts e
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

      # input {survey_id:, launch_id:, respondent_id:, responses:, pages:, responses_arr:, page_index_for_other_data:}
      def add_time_records_into_arr(input)
        start_time = Entity::Response.new(id: nil,
                                          respondent_id: input[:respondent_id],
                                          page_index: input[:page_index_for_other_data],
                                          item_order: 0,
                                          response: input[:responses]['moonbear_start_time'],
                                          item_data: nil)
        end_time = Entity::Response.new(id: nil,
                                        respondent_id: input[:respondent_id],
                                        page_index: input[:page_index_for_other_data],
                                        item_order: 1,
                                        response: input[:responses]['moonbear_end_time'],
                                        item_data: nil)
        input[:responses].delete('moonbear_start_time')
        input[:responses].delete('moonbear_end_time')
        time_records = [start_time, end_time]
        time_records.each { |record| input[:responses_arr].push(record) }

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to add time records into items array.')
      end

      # input {survey_id:, launch_id:, respondent_id:, responses:, pages:, responses_arr:, page_index_for_other_data:}
      def add_url_params_into_arr(input)
        unless input[:responses]['moonbear_url_params'].nil?
          url_param_item = Entity::Response.new(id: nil,
                                                respondent_id: input[:respondent_id],
                                                page_index: input[:page_index_for_other_data],
                                                item_order: 2,
                                                response: input[:responses]['moonbear_url_params'],
                                                item_data: nil)
          input[:responses_arr].push(url_param_item)
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to add url params into items array.')
      end

      # input {survey_id:, launch_id:, respondent_id:, responses:, pages:, responses_arr:, page_index_for_other_data:}
      def store_into_database(input)
        Repository::For[Entity::Launch].add_multi_responses(input[:launch_id], input[:responses_arr])
        Success(nil)
      rescue StandardError => e
        puts e
        Failure('Failed to store new responses into database.')
      end
    end
  end
end
