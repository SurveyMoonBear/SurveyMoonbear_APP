# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::GetPublicVisualReport.new.call(all_graphs: ..., case_email:..., redis:..., spreadsheet_id:..., user_key:...)
    class TransformPublicToCustomizedReport
      include Dry::Transaction
      include Dry::Monads

      step :get_sources_from_redis
      step :get_other_sheets_from_redis
      step :get_identity_with_sso_email
      step :transform_chart_color

      private

      # input { all_graphs:, case_email:, redis:, spreadsheet_id, user_key:}
      def get_sources_from_redis(input)
        input[:sources] = input[:redis].get(input[:user_key])['source']

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
            gid = url.match('#gid=([0-9]+)')[1]
            other_sheet_id = url.match('.*/(.*)/')[1]
            other_sheet_key = 'other_sheet' + other_sheet_id + 'gid' + gid
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
                                                           graph[9][input[:case_id]],
                                                           graph[10])
              end
          end
        end
        Success(input[:all_graphs])
      rescue StandardError
        Failure('Failed to transform chart color.')
      end

      # return colors
      def split_response_answer_and_transform_colors(labels, colors, case_response, survey_question_type)
        temp = labels.each_with_index.map { |label, idx| [label, colors[idx]] }
        temp = temp.to_h
        if survey_question_type
          temp = deal_with_diff_question(temp, case_response, survey_question_type)
        else
          temp[case_response] = 'rgb(255, 205, 86)'
        end
        temp.values
      end

      # C3:C141 shift(2) ;run 141-3+1 times;
      def transform_anotation(range)
        alphabet_table = { 'A' => 0, 'B' => 1, 'C' => 2, 'D' => 3, 'E' => 4, 'F' => 5, 'G' => 6, 'H' => 7, 'I' => 8, 'J' => 9,
                           'K' => 10, 'L' => 11, 'M' => 12, 'N' => 13, 'O' => 14, 'P' => 15, 'Q' => 16, 'R' => 17, 'S' => 18, 'T' => 19,
                           'U' => 20, 'V' => 21, 'W' => 22, 'X' => 23, 'Y' => 24, 'Z' => 25, 'AA' => 26, 'AB' => 27, 'AC' => 28, 'AD' => 29,
                           'AE' => 30, 'AF' => 31, 'AG' => 32, 'AH' => 33, 'AI' => 34, 'AJ' => 35, 'AK' => 36, 'AL' => 37, 'AM' => 38, 'AN' => 39,
                           'AO' => 40, 'AP' => 41, 'AQ' => 42, 'AR' => 43, 'AS' => 44, 'AT' => 45, 'AU' => 46, 'AV' => 47, 'AW' => 48, 'AX' => 49,
                           'AY' => 50, 'AZ' => 51, 'BA' => 52, 'BB' => 53, 'BC' => 54, 'BD' => 55, 'BE' => 56, 'BF' => 57,
                           'BG' => 58, 'BH' => 59, 'BI' => 60, 'BJ' => 61, 'BK' => 62, 'BL' => 63, 'BM' => 64, 'BN' => 65, 'BO' => 66 }
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

      def deal_with_diff_question(response_dic, case_response, survey_question_type)
        case survey_question_type
        when 'Multiple choice (radio button)'
          transform_multiple_choice_radio_color(response_dic, case_response)
        when "Multiple choice with 'other' (radio button)"
          transform_multiple_choice_radio_color(response_dic, case_response)
        when 'Multiple choice (checkbox)'
          transform_multiple_choice_checkbox_color(response_dic, case_response)
        when "Multiple choice with 'other' (checkbox)"
          transform_multiple_choice_checkbox_color(response_dic, case_response)
        when 'Multiple choice grid (radio button)'
          temp_option = {}
          response_dic.keys.each_with_index do |option, i|
            temp_option["#{i+1}"] = option # {'1'=>'Strongly Disagre', '2'=>'Disgree'...}
          end
          transform_choice_grid_color(response_dic, temp_option, case_response)
        else
          puts "Sorry, we are not yet able to support this question type: #{response_dic['type']}"
        end
      end

      def transform_multiple_choice_radio_color(response_dic, case_response)
        response_dic[case_response].nil? ? response_dic['other'] = 'rgb(255, 205, 86)' : response_dic[case_response] = 'rgb(255, 205, 86)'
        response_dic
      end

      def transform_multiple_choice_checkbox_color(response_dic, case_response)
        if case_response.include? ','
          new_case_response_arr = case_response.split(', ')
          new_case_response_arr.each_with_index do |res, i|
            if res.include? 'I sometimes ask questions about the homework'
              new_case_response_arr[i] = "I sometimes ask questions about the homework on MS Teams or read others' comments. 我有時會在微軟Teams上面發問或是瀏覽他人的討論串。"
            end
            response_dic[res].nil? ? response_dic['other'] = 'rgb(255, 205, 86)' : response_dic[res] = 'rgb(255, 205, 86)'
          end
        else
          response_dic[case_response].nil? ? response_dic['other'] = 'rgb(255, 205, 86)' : response_dic[case_response] = 'rgb(255, 205, 86)'
        end
        response_dic
      end

      def transform_choice_grid_color(response_dic, temp_option, case_response)
        response_dic[temp_option[case_response]] = 'rgb(255, 205, 86)'
        response_dic
      end
    end
  end
end
