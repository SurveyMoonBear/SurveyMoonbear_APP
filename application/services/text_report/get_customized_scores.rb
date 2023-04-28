# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetCustomizedScores
      include Dry::Transaction
      include Dry::Monads

      step :get_sources_from_redis
      step :get_other_sheets_from_redis
      step :get_identity_with_sso_email
      step :get_all_scores

      private

      # input { all_graphs:, case_email:, redis:, user_key:}
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
            ta_range = transform_anotation("A3:A144")
            help_range = transform_anotation("BB3:BB144")
            discuss_range = transform_anotation("BC3:BC144")
            all_email = get_range_val(input[:other_sheets][source[2]], email_range)
            all_case = get_range_val(input[:other_sheets][source[2]], case_range)
            all_ta = get_range_val(input[:other_sheets][source[2]], ta_range)
            all_help = get_range_val(input[:other_sheets][source[2]], help_range)
            all_discuss = get_range_val(input[:other_sheets][source[2]], discuss_range)
            all_email.each_with_index do |email, idx|
              if input[:case_email] == email
                input[:case_id] = all_case[idx]
                input[:ta] = all_ta[idx]
                input[:help] = all_help[idx]
                input[:discuss] = all_discuss[idx]
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
      def get_all_scores(input)
        scores = []
        input[:all_graphs].each do |page, graphs|
          graphs.each_with_index do |graph, idx|
            begin
            # scores.append({ 'Title' => graph[1], 'Score' => graph[8][input[:case_id]] })
              scores.append({ title: graph[1], score: graph[9][input[:case_id]], score_type: graph[8] })
            rescue StandardError => e 
            end
          end
        end
        result = { ta: input[:ta], scores: scores, help_count: input[:help], discuss_count: input[:discuss] }
        Success(result)
      rescue StandardError
        Failure('Failed to get all text scores.')
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
    end
  end
end
