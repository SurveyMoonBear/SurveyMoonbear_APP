# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::GetPublicVisualReport.new.call(all_graphs: ..., case_email:..., redis:..., spreadsheet_id:...)
    class TransformPublicToCustomizedReport
      include Dry::Transaction
      include Dry::Monads

      step :get_sources_from_redis
      step :get_other_sheets_from_redis
      step :get_identity_with_sso_email
      step :transform_chart_color

      private

      # input { all_graphs:, case_email:, redis:, spreadsheet_id}
      def get_sources_from_redis(input)
        input[:sources] = input[:redis].get('source'+input[:spreadsheet_id])

        if input[:sources]
          Success(input)
        else
          Failure('Failed to get sources from redis.')
        end
      end

      # input{ sources:, ...}
      def get_other_sheets_from_redis(input)
        input[:sources].each do |source|
          if source[0] == 'spreadsheet'
            url = source[1] # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
            other_sheet_id = url.match('.*/(.*)/')[1]
            other_sheet_key = 'other_sheet' + other_sheet_id
            input[:other_sheets] = input[:redis].get(other_sheet_key)
          end
        end
        Success(input)
      rescue StandardError
        Failure('Failed to get other sheets from redis.')
      end

      # input{ sources:, other_sheets:, all_graphs:, case_email:, ...}
      def get_identity_with_sso_email(input)
        input[:sources].each do |source|
          if source[4] && source[3]
            email_col = source[4] # I3:I140 sso_email
            case_id_col = source[3] #C3:C140 case_id
            email_range = transform_anotation(email_col)
            case_range = transform_anotation(case_id_col)
            all_email = get_range_val(input[:other_sheets][source[2]], email_range)
            all_case = get_range_val(input[:other_sheets][source[2]], case_range)
            all_email.each_with_index do |email, idx|
              if input[:case_email] == email
                input[:case_id] = all_case[idx]
                break
              end
            end
          end
        end
        Success(input)
      rescue StandardError
        Failure('Failed to map google account and spreadsheet case_id.')
      end

      # input{ case_id:, all_graphs:, ...}
      def transform_chart_color(input)
        input[:all_graphs].each do |page, graphs|
          graphs.each_with_index do |graph, idx|
            input[:all_graphs][page][idx][5] =
              if graph[7] == 'yes'
                split_response_answer_and_transform_colors(graph[4],
                                                           graph[5],
                                                           graph[8][input[:case_id]])
              end
          end
        end

        Success(input[:all_graphs])
      rescue StandardError
        Failure('Failed to transform chart color.')
      end

      def split_response_answer_and_transform_colors(labels, colors, case_response)
        temp = labels.each_with_index.map { |label, idx| [label, colors[idx]] }
        temp = temp.to_h
        if case_response.include? ','
          new_case_response_arr = case_response.split(', ')
          new_case_response_arr.each do |res|
            temp[res].nil? ? temp['other'] = 'rgb(255, 205, 86)' : temp[res] = 'rgb(255, 205, 86)'
          end
        else
          temp[case_response].nil? ? temp['other'] = 'rgb(255, 205, 86)' : temp[case_response] = 'rgb(255, 205, 86)'
        end
        # binding.irb
        temp.values
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
