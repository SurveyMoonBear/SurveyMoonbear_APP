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

        unless input[:sources]
          access_token = input[:access_token]

          update_visual_report = Service::UpdateVisualReport.new
                                                            .call(redis: redis,
                                                                  visual_report_id: visual_report_id,
                                                                  spreadsheet_id: spreadsheet_id,
                                                                  config: config,
                                                                  cache_key: cache_key,
                                                                  access_token: access_token)
          raise 'Failed to update visual report, please try again :(' if update_visual_report.failure?

          input[:sources] = input[:redis].get(input[:user_key])['source']
          raise('Failed to get sources from redis.') unless input[:sources]
        end

        Success(input)
      rescue StandardError => e
        Failure('Failed to get sources from redis.')
      end

      # input{ sources:, ...}
      def get_other_sheets_from_redis(input)
        other_sheet = {}
        input[:sources].each do |source|
          if source[0] == 'spreadsheet'
            url = source[1] # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
            gid = url.match('#gid=([0-9]+)')[1]
            other_sheet_id = url.match('.*/(.*)/')[1]
            other_sheet_key = source[2] + '/other_sheet' + other_sheet_id + 'gid' + gid
            other_sheet[source[2]] = input[:redis].get(other_sheet_key)
          end
          input[:other_sheets] = other_sheet
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
            name_col = source[5] #D3:D140 name
            email_range = transform_anotation(email_col)
            case_range = transform_anotation(case_id_col)
            name_range = transform_anotation(name_col)
            all_email = get_range_val(input[:other_sheets][source[2]], email_range)
            all_case = get_range_val(input[:other_sheets][source[2]], case_range)
            all_name = get_range_val(input[:other_sheets][source[2]], name_range)
            input[:all_name] = {}

            all_case.each_with_index do |case_id, idx|
              input[:all_name][case_id]= all_name[idx]
            end
            all_email.each_with_index do |email, idx|
              if input[:case_email].strip.downcase == email.strip.downcase
                input[:case_id] = all_case[idx]
                break
              end
            end
          end
        end
        Success(input)
      rescue StandardError => e 
        Failure('Failed to map google account and spreadsheet case_id.')
      end

      # input{ case_id:, all_graphs:, ...}
      def get_all_scores(input)
        scores = []
        input[:all_graphs].each do |page, graphs|
          graphs.each_with_index do |graph, idx|
            begin
              student_score = graph[10][input[:case_id]]
              next if (student_score.nil? || student_score.to_s.strip.empty?) && graph[8] != 'discuss'

              scores.append({
                title: graph[1],
                score: student_score,
                score_type: graph[8],
                all_scores: graph[10],
                params: graph[9],
                all_name: input[:all_name],
                student_id: input[:case_id]
              })
            rescue StandardError => e
            end
          end
        end
        result = { scores: scores }
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
