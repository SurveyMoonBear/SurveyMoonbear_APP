# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return an array of page HTML strings
    # Usage: Service::TransformVisualSheetsToChart.new.call(survey_id: "...", spreadsheet_id: "...", config: "...", redis: "...", access_token: "...")
    class TransformVisualSheetsToChart
      include Dry::Transaction
      include Dry::Monads

      step :get_items_from_spreadsheet
      step :get_user_access_token
      step :get_sources_from_spreadsheet
      step :cal_responses_from_sources

      private

      # input { visual_report_id:, spreadsheet_id:, access_token:, config:, redis:}
      def get_items_from_spreadsheet(input)
        sheets_report = GetVisualreportFromSpreadsheet.new.call(spreadsheet_id: input[:spreadsheet_id],
                                                                access_token: input[:access_token],
                                                                redis: input[:redis])
        if sheets_report.success?
          input[:sheets_report] = sheets_report.value! # table1=>[table1 data],table2=>[table2 data]...
          Success(input)
        else
          Failure(sheets_report.failure)
        end
      end

      # input { ..., sheets_report}
      def get_user_access_token(input)
        visual_report = Repository::For[Entity::VisualReport].find_origin_id(input[:spreadsheet_id])
        refresh_token = visual_report.owner.refresh_token
        input[:user_access_token] = Google::Auth.new(input[:config]).refresh_user_access_token(refresh_token)

        if input[:user_access_token]
          Success(input)
        else
          Failure("Failed to get user's access token.")
        end
      end

      # input { ..., sheets_report, user_access_token}
      def get_sources_from_spreadsheet(input)
        sources = GetSourcesFromSpreadsheet.new.call(spreadsheet_id: input[:spreadsheet_id],
                                                     access_token: input[:access_token],
                                                     redis: input[:redis])

        other_sheet = {}
        sources.value!.each do |source|
          if source.source_type == 'spreadsheet'
            url = source.source_name # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
            other_sheet_id = url.match('.*/(.*)/')[1]
            other_sheets_api = Google::Api::Sheets.new(input[:user_access_token])
            other_sheet_key = 'other_sheet' + other_sheet_id
            input[:other_sheets] =
              if input[:redis].get(other_sheet_key)
                input[:redis].get(other_sheet_key)
              else
                other_sheet_title = other_sheets_api.survey_data(other_sheet_id)['sheets'][0]['properties']['title']
                other_sheet[source.source_id] = other_sheets_api.items_data(other_sheet_id, other_sheet_title)['values'].reject(&:empty?)
                input[:redis].set(other_sheet_key, other_sheet)
                other_sheet
              end
          end
        end

        if sources.success?
          input[:sources] = sources.value!
          Success(input)
        else
          Failure(sources.failure)
        end
      end

      # input { ..., sheets_report, user_access_token, sources}
      def cal_responses_from_sources(input)
        pages_val =
          input[:sheets_report].map do |key, items_data|
            graphs_val =
              items_data.map do |item_data|
                source = find_source(input[:sources], item_data.data_source)
                case source.source_type
                when 'surveymoonbear'
                  MapSurveyResponsesAndItems.new.call(item_data: item_data,
                                                      source: source).value!

                when 'spreadsheet'
                  MapSpreadsheetResponsesAndItems.new.call(item_data: item_data,
                                                           access_token: input[:user_access_token],
                                                           spreadsheet_source: source,
                                                           all_data: input[:other_sheets][source.source_id]).value!
                else
                  Failure('Source type is wrong!')
                end
              end
            [key, graphs_val]
          end
        input[:all_graphs] = pages_val.to_h

        Success(input[:all_graphs])
      rescue StandardError
        Failure('Failed to map responses and visual report items.')
      end

      def find_source(sources, item_data_source)
        sources.each do |source|
          if item_data_source == source.source_id
            return source
          end
        end
      end
    end
  end
end
