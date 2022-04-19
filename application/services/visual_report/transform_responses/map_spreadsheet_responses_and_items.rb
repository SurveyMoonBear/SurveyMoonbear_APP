require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return graph array:
    # [item_data.page, item_data.graph_title, item_data.chart_type, response_cal_hash, labels, chart_colors]
    # Usage: Service::MapSpreadsheetResponsesAndItems.new.call(item_data: "...", spreadsheet_source: "...", vis_identity: "...")
    class MapSpreadsheetResponsesAndItems
      include Dry::Transaction
      include Dry::Monads

      # step :get_sheet_from_spreadsheet
      step :get_responses_from_spreadsheet
      step :map_identity_and_responses
      step :map_individual_answer
      step :return_graph_result

      private

      # input{ item_data:..., access_token:..., spreadsheet_source:..., vis_identity:...}
      # def get_sheet_from_spreadsheet(input)
      #   url = input[:spreadsheet_source].source_name # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
      #   input[:spreadsheet_id] = url.match('.*/(.*)/')[1]
      #   input[:sheets_api] = Google::Api::Sheets.new(input[:access_token])

      #   Success(input)
      # rescue StandardError => e
      #   puts e
      #   Failure('Failed to read source spreadsheet.')
      # end

      # input{ first_sheet:..., sheets_api:..., spreadsheet_id:...}
      def get_responses_from_spreadsheet(input)
        case_id = input[:spreadsheet_source].case_id # C3:C141
        question = input[:item_data].question # M3:M141

        unless case_id.nil?
          case_range = transform_anotation(case_id)
          input[:case_id_val] = get_range_val(input[:all_data], case_range)
        end
        question_range = transform_anotation(question)
        input[:res_val] = get_range_val(input[:all_data], question_range)

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to read first sheet data.')
      end

      def map_identity_and_responses(input)
        input[:count] = {}
        input[:new_values] = transfom_sheet_val(input[:res_val])
        input[:count] = input[:new_values].tally
        input[:count] = input[:count].sort.to_h

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to map identity and responses which the sources from spreadsheet url.')
      end

      def map_individual_answer(input)
        chart_colors = {}
        input[:count].each_key { |key| chart_colors[key] = 'rgb(54, 162, 235)' }
        unless input[:case_id_val].nil?
          input[:case_id_val].each_with_index do |id, idx|
            if id == input[:vis_identity]
              chart_colors[input[:new_values][idx]] = 'rgb(255, 205, 86)'
            end
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

      def transfom_sheet_val(values_arr)
        new_values = []
        values_arr.each do |val|
          if val.nil? || val.empty?
            new_values.append('0')
          else
            new_values.append(val)
          end
        end
        new_values
      end

      # C3:C141 shift(2) ;run 141-3+1 times;
      def transform_anotation(range)
        alphabet_table = { 'A' => 0, 'B' => 1, 'C' => 2, 'D' => 3, 'E' => 4, 'F' => 5, 'G' => 6, 'H' => 7, 'I' => 8, 'J' => 9,
                           'K' => 10, 'L' => 11, 'M' => 12, 'N' => 13, 'O' => 14, 'P' => 15, 'Q' => 16, 'R' => 17, 'S' => 18, 'T' => 19,
                           'U' => 20, 'V' => 21, 'W' => 22, 'X' => 23, 'Y' => 24, 'Z' => 25, 'AA' => 26, 'AB' => 27, 'AC' => 28, 'AD' => 29,
                           'AE' => 30, 'AF' => 31, 'AG' => 32, 'AH' => 33, 'AI' => 34, 'AJ' => 35, 'AK' => 36, 'AL' => 37, 'AM' => 38, 'AN' => 39,
                           'AO' => 40, 'AP' => 41, 'AQ' => 42, 'AR' => 43, 'AS' => 44, 'AT' => 45, 'AU' => 46, 'AV' => 47, 'AW' => 48, 'AX' => 49,
                           'AY' => 50, 'AZ' => 51 }
        range = range.split(':')
        start_row = range[0].split(/([A-Z]+)/)
        start_row.shift
        end_row = range[1].split(/([A-Z]+)/)
        end_row.shift
        column_times = alphabet_table[end_row[0]] - alphabet_table[start_row[0]] + 1
        row_times = end_row[1].to_i - start_row[1].to_i + 1
        { 'shift_num': (start_row[1].to_i) - 1,
          'column': alphabet_table[start_row[0]],
          'column_times': column_times,
          'row_times': row_times }
      end

      def get_range_val(all_data, case_range)
        new_val = []
        data = all_data.drop(case_range[:shift_num])
        data.each_with_index do |row_value, idx|
          break if idx == case_range[:row_times]

          new_val.append(row_value[case_range[:column]])
        end
        new_val
      end
    end
  end
end
