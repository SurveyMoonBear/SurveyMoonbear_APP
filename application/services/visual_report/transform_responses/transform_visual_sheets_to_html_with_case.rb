# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformVisualSheetsToHTMLWithCase.new.call(spreadsheet_id: ..., config: ..., access_token: ..., case_email:...)
    class TransformVisualSheetsToHTMLWithCase
      include Dry::Transaction
      include Dry::Monads

      step :get_items_from_spreadsheet
      step :get_user_access_token
      step :get_sources_from_spreadsheet
      step :get_identity_with_sso_email
      step :get_responses_from_sources
      step :transform_sheet_items_to_html

      private

      # input { spreadsheet_id:, access_token:, config: }
      def get_items_from_spreadsheet(input)
        sheets_report = GetVisualreportFromSpreadsheet.new.call(spreadsheet_id: input[:spreadsheet_id],
                                                                access_token: input[:access_token])
        if sheets_report.success?
          input[:sheets_report] = sheets_report.value!
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
                                                     access_token: input[:access_token])
        other_sheet = {}
        sources.value!.each do |source|
          if source.source_type == 'spreadsheet'
            url = source.source_name # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
            other_sheet_id = url.match('.*/(.*)/')[1]
            other_sheets_api = Google::Api::Sheets.new(input[:user_access_token])
            other_sheet_title = other_sheets_api.survey_data(other_sheet_id)['sheets'][0]['properties']['title']
            other_sheet[source.source_id] = other_sheets_api.items_data(other_sheet_id, other_sheet_title)['values'].reject(&:empty?)
            input[:other_sheets] = other_sheet
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
      def get_identity_with_sso_email(input)
        input[:sources].each do |source|
          if source.sso_email && source.case_id
            email_col = source.sso_email #I3:I140
            case_id_col = source.case_id #C3:C140
            email_range = transform_anotation(email_col)
            case_range = transform_anotation(case_id_col)
            all_email = get_range_val(input[:other_sheets][source.source_id], email_range)
            all_case = get_range_val(input[:other_sheets][source.source_id], case_range)
            all_email.each_with_index do |email, idx|
              if input[:case_email] == email
              # if 'wisarud.y@gmail.com' == email
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

      # input { ..., sheets_report, user_access_token, sources, case_id}
      def get_responses_from_sources(input)
        pages_val = {}
        input[:sheets_report].each do |key, items_data|
          graphs_val = []
          items_data.each do |item_data|
            source = find_source(input[:sources], item_data.data_source)

            if source.source_type == 'surveymoonbear'
              survey = Repository::For[Entity::Survey].find_title(source.source_name)
              launch = Repository::For[Entity::Launch].find_id(survey.launch_id)
              vis_identity = input[:case_id].nil? ? nil : find_respondent_id(input[:case_id], launch.responses)
              graphs_val.append(map_moonbear_responses_and_report_item(item_data,
                                                                       launch.responses,
                                                                       vis_identity))
            elsif source.source_type == 'spreadsheet'
              graph_response = MapSpreadsheetResponsesAndItems.new.call(item_data: item_data,
                                                                        access_token: input[:access_token],
                                                                        spreadsheet_source: source,
                                                                        all_data: input[:other_sheets][source.source_id],
                                                                        vis_identity: input[:case_id])
              graphs_val.append(graph_response.value![:graph_val])
            end
          end
          pages_val[key] = graphs_val
        end
        input[:all_graphs] = pages_val

        Success(input)
      rescue StandardError
        Failure('Failed to map responses and visual report items.')
      end

      # input { ..., all_graphs:}
      def transform_sheet_items_to_html(input)
        transform_result = TransformResponsesToHTMLWithChart.new.call(pages_charts: input[:all_graphs])

        if transform_result.success?
          Success(all_graphs: input[:all_graphs],
                  nav_tab: transform_result.value![:nav_tab],
                  nav_item: transform_result.value![:nav_item],
                  pages_chart_val_hash: transform_result.value![:pages_chart_val_hash])
        else
          Failure(transform_result.failure)
        end
      end

      def map_moonbear_responses_and_report_item(item_data, bear_responses, vis_identity)
        response_cal_hash = {}
        chart_colors = {}
        item_responses = {}
        item_options = []
        item_all_responses = [] # only response
        graph_val = []

        bear_responses.each do |res_obj|
          if !res_obj.item_data.nil?
          question = JSON.parse(res_obj.item_data)
            if question['name'] == item_data.question
              item_all_responses.append(res_obj.response)
              item_responses['type'] = question['type']
              item_options = question['options'] if !question['options'].nil?
              item_responses['case_response'] = res_obj.response if vis_identity == res_obj.respondent_id
            end
          end
        end
        item_responses['responses'] = item_all_responses
        item_responses['self_marker'] = item_data.self_marker == 'yes'

        # calculate each question's option
        if !item_options.empty?
          options = item_options.gsub("\n", '')
          options = options.split(',')
          options.each do |option|
            response_cal_hash[option] = 0
            chart_colors[option] = 'rgb(54, 162, 235)'
          end

          response_cal_hash, chart_colors = cal_individual_question(item_responses, options, chart_colors, response_cal_hash, vis_identity)
        end

        graph_val.append(item_data.page,
                         item_data.graph_title,
                         item_data.chart_type,
                         response_cal_hash.values,
                         chart_colors.keys,
                         chart_colors.values,
                         item_data.legend)
      end

      # case_id will transform to uuid respondent_id
      def find_respondent_id(identity, responses)
        responses.each do |res_obj|
          if identity == res_obj.response
            return res_obj.respondent_id
          end
        end
        nil
      end

      def find_source(sources, item_data_source)
        sources.each do |source|
          if item_data_source == source.source_id
            return source
          end
        end
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

      def cal_individual_question(response_dic, options, chart_colors, response_cal_hash, vis_identity)
        response_cal_hash, chart_colors =
          case response_dic['type']
          when 'Multiple choice (radio button)'
            cal_multiple_choice_radio(response_dic, chart_colors, response_cal_hash, vis_identity)
          when "Multiple choice with 'other' (radio button)"
            cal_multiple_choice_radio_with_other(response_dic, chart_colors, response_cal_hash, vis_identity)
          when 'Multiple choice (checkbox)'
            responses_arr = []
            response_dic['responses'].each do |responses_perperson|
              responses_arr += responses_perperson.split(', ')
            end
            cal_multiple_choice_checkbox(response_dic, responses_arr, chart_colors, response_cal_hash, vis_identity)
          when "Multiple choice with 'other' (checkbox)"
            responses_arr = []
            response_dic['responses'].each do |responses_perperson|
              responses_arr += responses_perperson.split(', ')
            end

            cal_multiple_choice_checkbox_with_other(response_dic, responses_arr, chart_colors, response_cal_hash, vis_identity)
          when 'Multiple choice grid (radio button)'
            temp_option={}
            options.each_with_index do |option, i|
              temp_option["#{i+1}"]=option # {'1'=>'Strongly Disagre', '2'=>'Disgree'...}
            end
            cal_choice_grid(response_dic, temp_option, chart_colors, response_cal_hash, vis_identity)
          else
            puts "Sorry, we are not yet able to support this question type: #{response_dic['type']}"
          end
        return response_cal_hash, chart_colors
      end

      def cal_multiple_choice_radio(response_dic, chart_colors, response_cal_hash, vis_identity)
        responses_hash = response_dic['responses'].tally
        response_cal_hash.each_key { |key| responses_hash[key].nil? ? 0 : response_cal_hash[key] = responses_hash[key] }
        chart_colors[response_dic['case_response']] = 'rgb(255, 205, 86)' if response_dic['self_marker'] && vis_identity

        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_radio_with_other(response_dic, chart_colors, response_cal_hash, vis_identity)
        responses_hash = response_dic['responses'].tally
        response_cal_hash.each_key do |key|
          responses_hash[key].nil? ? 0 : response_cal_hash[key] = responses_hash[key]
          responses_hash.delete(key)
        end
        response_cal_hash['other'] = 0
        responses_hash.each_value { |val| response_cal_hash['other'] += val }

        chart_colors['other'] = 'rgb(54, 162, 235)'
        if response_dic['self_marker'] && vis_identity
          chart_colors[response_dic['case_response']].nil? ? chart_colors['other'] = 'rgb(255, 205, 86)' : chart_colors[response_dic['case_response']] = 'rgb(255, 205, 86)'
        end
        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_checkbox(response_dic, responses_arr, chart_colors, response_cal_hash, vis_identity)
        responses_hash = responses_arr.tally
        response_cal_hash.each_key do |key|
          response_cal_hash[key] = responses_hash[key]
        end
        if response_dic['self_marker'] && vis_identity
          case_res_arr = response_dic['case_response'].split(', ')
          case_res_arr.each do |case_res|
            chart_colors[case_res] = 'rgb(255, 205, 86)'
          end
        end
        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_checkbox_with_other(response_dic, responses_arr, chart_colors, response_cal_hash, vis_identity)
        responses_arr.each_with_index do |r, i|
          if r.include? 'I sometimes ask questions about the homework'
            responses_arr[i] = "I sometimes ask questions about the homework on MS Teams or read others' comments. 我有時會在微軟Teams上面發問或是瀏覽他人的討論串。"
          end
        end
        responses_hash = responses_arr.tally
        response_cal_hash.each_key do |key|
          responses_hash[key].nil? ? 0 : response_cal_hash[key] = responses_hash[key]
          responses_hash.delete(key)
        end
        response_cal_hash['other'] = 0
        responses_hash.each_value { |val| response_cal_hash['other'] += val }

        chart_colors['other'] = 'rgb(54, 162, 235)'
        if response_dic['self_marker'] && vis_identity
          case_res_arr = response_dic['case_response'].split(', ')
          case_res_arr.each_with_index do |r, i|
            if r.include? 'I sometimes ask questions about the homework'
              case_res_arr[i] = "I sometimes ask questions about the homework on MS Teams or read others' comments. 我有時會在微軟Teams上面發問或是瀏覽他人的討論串。"
            end
          end
          case_res_arr.each do |case_res|
            chart_colors[case_res].nil? ? chart_colors['other'] = 'rgb(255, 205, 86)' : chart_colors[case_res] = 'rgb(255, 205, 86)'
          end
        end
        [response_cal_hash, chart_colors]
      end

      def cal_choice_grid(response_dic, temp_option, chart_colors, response_cal_hash, vis_identity)
        responses_hash = response_dic['responses'].sort.tally
        responses_hash.each_key do |key|
          response_cal_hash[temp_option[key]] = responses_hash[key]
        end
        chart_colors[temp_option[response_dic['case_response']]] = 'rgb(255, 205, 86)' if response_dic['self_marker'] && vis_identity

        [response_cal_hash, chart_colors]
      end
    end
  end
end
