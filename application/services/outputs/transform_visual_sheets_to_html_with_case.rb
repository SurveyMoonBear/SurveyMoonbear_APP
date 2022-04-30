# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformVisualSheetsToHTMLWithCase.new.call(survey_id: "...", spreadsheet_id: "...", access_token: "...", student_id: "...")
    class TransformVisualSheetsToHTMLWithCase
      include Dry::Transaction
      include Dry::Monads

      step :get_items_from_spreadsheet
      step :get_sources_from_spreadsheet
      step :get_responses_from_sources
      step :transform_sheet_items_to_html

      private

      # input { visual_report_id:, spreadsheet_id:, access_token:, current_account: }
      def get_items_from_spreadsheet(input)
        # sheets_report有兩層array TODO
        sheets_report = GetVisualreportFromSpreadsheet.new.call(spreadsheet_id: input[:spreadsheet_id],
                                                                access_token: input[:access_token])

        if sheets_report.success?
          input[:sheets_report] = sheets_report.value![0] # 因為兩層array所以才加 [0]
          Success(input)
        else
          Failure(sheets_report.failure)
        end
      end

      # input { ..., sheets_report}
      def get_sources_from_spreadsheet(input)
        sources = GetSourcesFromSpreadsheet.new.call(spreadsheet_id: input[:spreadsheet_id],
                                                     access_token: input[:access_token])

        other_sheet = {}
        sources.value!.each do |source|
          if source.source_type == 'spreadsheet'
            url = source.source_name # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
            other_sheet_id = url.match('.*/(.*)/')[1]
            other_sheets_api = Google::Api::Sheets.new(input[:access_token])
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

      # input { ..., sheets_report}
      def get_responses_from_sources(input)
        graphs_val = []
        input[:sheets_report].each do |item_data|
          source = find_source(input[:sources], item_data.data_source)

          if source.source_type == 'surveymoonbear'
            survey = Repository::For[Entity::Survey].find_title(source.source_name)
            launch = Repository::For[Entity::Launch].find_id(survey.launch_id)
            vis_identity = find_respondent_id(input[:student_id], launch.responses) # 109003888 will transform to uuid respondent_id
            graphs_val.append(map_moonbear_responses_and_report_item(item_data,
                                                                     launch.responses,
                                                                     vis_identity))
          elsif source.source_type == 'spreadsheet'
            graph_response = MapSpreadsheetResponsesAndItems.new.call(item_data: item_data,
                                                                      access_token: input[:access_token],
                                                                      spreadsheet_source: source,
                                                                      all_data: input[:other_sheets][source.source_id],
                                                                      vis_identity: input[:student_id])
            graphs_val.append(graph_response.value![:graph_val])
          end
        end
        input[:all_graphs] = graphs_val

        Success(input)
      rescue StandardError
        Failure('Failed to map responses and visual report items.')
      end

      # input { ..., sheets_report:, bear_responses: ,all_graphs:}
      def transform_sheet_items_to_html(input)
        transform_result = TransformResponsesToHTMLWithChart.new.call(charts: input[:all_graphs])

        if transform_result.success?
          Success(all_graphs: input[:all_graphs],
                  html_arr: transform_result.value!)
        else
          Failure(transform_result.failure)
        end
      end

      def map_moonbear_responses_and_report_item(item_data, bear_responses, vis_identity)
        response_cal_hash = {}
        chart_colors = {}
        item_responses = {} # { responses: item_all_responses, type: question['type'], res_id: 109003888}
        item_options = []
        item_all_responses = [] # only response
        graph_val = []
        # 每個回覆中 哪些回覆是需要被visualize的 每一列的visual都有其responses了
        bear_responses.each do |res_obj|
          if !res_obj.item_data.nil?
          question = JSON.parse(res_obj.item_data)
            if question['name'] == item_data.question
              # item_responses[res_obj.respondent_id] = {} if item_responses[res_obj.respondent_id].nil?
              # item_responses[res_obj.respondent_id]['responses'] = res_obj.response
              item_all_responses.append(res_obj.response)
              # item_responses[res_obj.respondent_id]['type'] = question['type']
              item_responses['type'] = question['type']
              item_options = question['options'] if !question['options'].nil?
              item_responses['case_response'] = res_obj.response if vis_identity == res_obj.respondent_id
            end
          end
        end
        item_responses['responses'] = item_all_responses
        item_responses['case_id'] = vis_identity

        # response_cal_hash.keys = chart_labels; response_cal_hash.values = chart_datas ; chart_colors.values = chart_colors
        # 計算單一問題的每個答案的次數
        if !item_options.empty?
          options = item_options.gsub("\n", '')
          options = options.split(',')
          # options = options.map { |option| option.gsub("\n", '') }
          options.each do |option|
            response_cal_hash[option] = 0
            chart_colors[option] = 'rgb(54, 162, 235)'
          end

          response_cal_hash, chart_colors = cal_individual_question(item_responses, options, chart_colors, response_cal_hash)
          # options.each do |option|
          #   item_responses.each_key do |res_id| # k=respondent_id
          #     response_cal_hash, chart_colors = cal_individual_question(item_responses[res_id],
          #                                                               options,
          #                                                               option,
          #                                                               chart_colors,
          #                                                               response_cal_hash,
          #                                                               res_id,
          #                                                               vis_identity)
          #   end
          # end
        end

        graph_val.append(item_data.page,
                         item_data.graph_title,
                         item_data.chart_type,
                         response_cal_hash.values,
                         chart_colors.keys,
                         chart_colors.values,
                         item_data.legend)
      end

      def find_respondent_id(identity, responses)
        responses.each do |res_obj|
          if identity == res_obj.response
            return res_obj.respondent_id
          end
        end
      end

      def find_source(sources, item_data_source)
        sources.each do |source|
          if item_data_source == source.source_id
            return source
          end
        end
        # return error? nil?
      end

      def cal_individual_question(response_dic, options, chart_colors, response_cal_hash)
        response_cal_hash, chart_colors =
          case response_dic['type']
          when 'Multiple choice (radio button)'
            cal_multiple_choice_radio(response_dic, chart_colors, response_cal_hash)
          when "Multiple choice with 'other' (radio button)"
            cal_multiple_choice_radio_with_other(response_dic, chart_colors, response_cal_hash)
          when 'Multiple choice (checkbox)'
            # response_dic['responses'] = response_dic['responses'].tr("\n", '')
            responses_arr = []
            response_dic['responses'].each do |responses_perperson|
              responses_arr += responses_perperson.split(', ')
            end
            cal_multiple_choice_checkbox(response_dic, responses_arr, chart_colors, response_cal_hash)
          when "Multiple choice with 'other' (checkbox)"
            # response_dic['responses'] = response_dic['responses'].tr("\n", '')
            responses_arr = []
            response_dic['responses'].each do |responses_perperson|
              responses_arr += responses_perperson.split(', ')
            end

            cal_multiple_choice_checkbox_with_other(response_dic, responses_arr, chart_colors, response_cal_hash)
          when 'Multiple choice grid (radio button)'
            temp_option={}
            options.each_with_index do |option, i|
              temp_option["#{i+1}"]=option # {'1'=>'Strongly Disagre', '2'=>'Disgree'...}
            end
            cal_choice_grid(response_dic, temp_option, chart_colors, response_cal_hash)
          else
            puts "Sorry, we are not yet able to support this question type: #{response_dic['type']}"
          end
        return response_cal_hash, chart_colors
      end

      def cal_multiple_choice_radio(response_dic, chart_colors, response_cal_hash)
        responses_hash = response_dic['responses'].tally
        response_cal_hash.each_key { |key| responses_hash[key].nil? ? 0 : response_cal_hash[key] = responses_hash[key] }
        chart_colors[response_dic['case_response']] = 'rgb(255, 205, 86)'

        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_radio_with_other(response_dic, chart_colors, response_cal_hash)
        responses_hash = response_dic['responses'].tally
        response_cal_hash.each_key do |key|
          responses_hash[key].nil? ? 0 : response_cal_hash[key] = responses_hash[key]
          responses_hash.delete(key)
        end
        response_cal_hash['other'] = 0
        responses_hash.each_value { |val| response_cal_hash['other'] += val }

        chart_colors['other'] = 'rgb(54, 162, 235)'
        chart_colors[response_dic['case_response']].nil? ? chart_colors['other'] = 'rgb(255, 205, 86)' : chart_colors[response_dic['case_response']] = 'rgb(255, 205, 86)'

        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_checkbox(response_dic, responses_arr, chart_colors, response_cal_hash)
        responses_hash = responses_arr.tally
        response_cal_hash.each_key do |key|
          response_cal_hash[key] = responses_hash[key]
        end
        case_res_arr = response_dic['case_response'].split(', ')
        case_res_arr.each do |case_res|
          chart_colors[case_res] = 'rgb(255, 205, 86)'
        end
        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_checkbox_with_other(response_dic, responses_arr, chart_colors, response_cal_hash)
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
        case_res_arr = response_dic['case_response'].split(', ')
        case_res_arr.each_with_index do |r, i|
          if r.include? 'I sometimes ask questions about the homework'
            case_res_arr[i] = "I sometimes ask questions about the homework on MS Teams or read others' comments. 我有時會在微軟Teams上面發問或是瀏覽他人的討論串。"
          end
        end
        case_res_arr.each do |case_res|
          chart_colors[case_res].nil? ? chart_colors['other'] = 'rgb(255, 205, 86)' : chart_colors[case_res] = 'rgb(255, 205, 86)'
        end

        [response_cal_hash, chart_colors]
      end

      def cal_choice_grid(response_dic, temp_option, chart_colors, response_cal_hash)
        responses_hash = response_dic['responses'].sort.tally
        responses_hash.each_key do |key|
          response_cal_hash[temp_option[key]] = responses_hash[key]
        end
        chart_colors[temp_option[response_dic['case_response']]] = 'rgb(255, 205, 86)'

        [response_cal_hash, chart_colors]
      end
    end
  end
end
