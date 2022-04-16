require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return graph array:
    # [item_data.page, item_data.graph_title, item_data.chart_type, response_cal_hash, labels, chart_colors]
    # Usage: Service::MapSpreadsheetResponsesAndItems.new.call(item_data: "...", spreadsheet_source: "...", vis_identity: "...")
    class MapSpreadsheetResponsesAndItems
      include Dry::Transaction
      include Dry::Monads

      step :get_sheet_from_spreadsheet
      step :get_responses_from_spreadsheet
      step :map_identity_and_responses
      step :map_individual_answer
      step :return_graph_result

      private

      # input{ item_data:..., access_token:..., spreadsheet_source:..., vis_identity:...}
      def get_sheet_from_spreadsheet(input)
        url = input[:spreadsheet_source].source_name # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
        input[:spreadsheet_id] = url.match('.*/(.*)/')[1]
        input[:sheets_api] = Google::Api::Sheets.new(input[:access_token])
        # input[:first_sheet] = input[:sheets_api].survey_data(input[:spreadsheet_id])['sheets'][0]['properties']

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to read source spreadsheet.')
      end

      # input{ first_sheet:..., sheets_api:..., spreadsheet_id:...}
      def get_responses_from_spreadsheet(input)
        case_id = input[:spreadsheet_source].case_id
        question_range = input[:item_data].question
        # ranges=A1:D5&ranges=Sheet2!A1:C4
        ranges =
          if case_id.nil?
            "ranges=#{question_range}"
          else
            "ranges=#{question_range}&ranges=#{case_id}"
          end
        input[:id_n_res] = input[:sheets_api].get_range_data(input[:spreadsheet_id], ranges)

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to read first sheet data.')
      end

      def map_identity_and_responses(input)
        input[:count] = {}
        input[:id_order] = []

        # when idx=1, it will be case_id
        # ident_n_res['valueRanges'][0]['values'] identities_n_responses['valueRanges'][1]['values']
        input[:id_n_res]['valueRanges'].each_with_index do |val_range, idx|
          if idx == 1
            input[:id_order] = transfom_sheet_val(val_range['values'])
          else
            input[:new_values] = transfom_sheet_val(val_range['values'])
            input[:count] = input[:new_values].tally
          end
        end
        input[:count] = input[:count].sort.to_h
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to map identity and responses which the sources from spreadsheet url.')
      end

      def map_individual_answer(input)
        chart_colors = {}
        input[:count].each_key { |key| chart_colors[key] = 'rgb(54, 162, 235)' }
        input[:id_order].each_with_index do |id, idx|
          if id == input[:vis_identity]
            chart_colors[input[:new_values][idx]] = 'rgb(255, 205, 86)'
          end
        end
        input[:chart_colors] = chart_colors

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to map individual answer which the sources from spreadsheet url.')
      end

      def return_graph_result(input)
        graph_val = []
        graph_val.append(input[:item_data].page,
                         input[:item_data].graph_title,
                         input[:item_data].chart_type,
                         input[:count].values,
                         input[:count].keys,
                         input[:chart_colors].values)
        input[:graph_val] = graph_val

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to return graph results which the sources from spreadsheet url.')
      end
      # sometimes it will have empty data, and the wired Response(e.g., [[val],[val2],[]) from google spreadsheet
      def transfom_sheet_val(values_arr)
        new_values = []
        values_arr.each do |val|
          if val.nil? || val.empty?
            new_values.append('0')
          else
            new_values.append(val[0])
          end
        end
        new_values
      end
    end
  end
end
