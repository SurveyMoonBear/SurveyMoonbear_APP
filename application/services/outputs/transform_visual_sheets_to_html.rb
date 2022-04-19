# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformVisualSheetsToHTML.new.call(survey_id: "...", spreadsheet_id: "...", access_token: "...", student_id: "...")
    class TransformVisualSheetsToHTML
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
            vis_identity = find_respondent_id(input[:student_id], launch.responses) # 109003888
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
        item_responses = {}
        item_options = []
        graph_val = []
        # 每個回覆中 哪些回覆是需要被visualize的 每一列的visual都有其responses了
        bear_responses.each do |res_obj|
          if !res_obj.item_data.nil?
          question = JSON.parse(res_obj.item_data)
            if question['description'] == item_data.question
              item_responses[res_obj.respondent_id] = {} if item_responses[res_obj.respondent_id].nil?
              item_responses[res_obj.respondent_id]['responses'] = res_obj.response
              item_responses[res_obj.respondent_id]['type'] = question['type']
              item_options = question['options'] if !question['options'].nil?
            end
          end
        end

        # response_cal_hash.keys = chart_labels; response_cal_hash.values = chart_datas ; chart_colors.values = chart_colors
        # 計算單一問題的每個答案的次數
        if !item_options.empty?
          options = item_options.split(',')
          options = options.map { |option| option.gsub("\n", '') }
          options.each { |option| response_cal_hash[option] = 0 }
          response_cal_hash['other'] = 0

          options.each do |option|
            chart_colors[option] = 'rgb(54, 162, 235)'
            chart_colors['other'] = 'rgb(54, 162, 235)'
            item_responses.each_key do |res_id| # k=respondent_id
              response_cal_hash, chart_colors = cal_individual_question(item_responses[res_id],
                                                                        options,
                                                                        option,
                                                                        chart_colors,
                                                                        response_cal_hash,
                                                                        res_id,
                                                                        vis_identity)
            end
          end
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

      def cal_individual_question(response_dic, options, option, chart_colors, response_cal_hash, res_id, vis_identity)
        response_cal_hash, chart_colors =
          case response_dic['type']
          when 'Multiple choice (radio button)'
            response_cal_hash.delete('other')
            chart_colors.delete('other')
            build_multiple_choice_radio(response_dic, option, chart_colors, response_cal_hash, vis_identity, res_id, other=false)
          when "Multiple choice with 'other' (radio button)"
            other = !(options.include? response_dic['responses'])
            # response_cal_hash.delete('other') if response_cal_hash['other'] < 1 && !other
            build_multiple_choice_radio(response_dic, option, chart_colors, response_cal_hash, vis_identity, res_id, other)
          when 'Multiple choice (checkbox)'
            response_cal_hash.delete('other')
            chart_colors.delete('other')
            response_dic['responses'] = response_dic['responses'].tr("\n", '')
            responses_arr = response_dic['responses'].split(', ')
            build_multiple_choice_checkbox(responses_arr, option, chart_colors, response_cal_hash, res_id, other=false)
          when "Multiple choice with 'other' (checkbox)"
            response_dic['responses'] = response_dic['responses'].tr("\n", '')
            responses_arr = response_dic['responses'].split(', ')
            other = (responses_arr - options).empty? ? false : options.include?(responses_arr - options)
            # response_cal_hash.delete('other') if response_cal_hash['other'] < 1 && !other
            build_multiple_choice_checkbox(responses_arr, option, chart_colors, response_cal_hash, vis_identity, res_id, other)
          else
            puts "Sorry, we are not yet able to support this question type: #{response_dic['type']}"
          end
        return response_cal_hash, chart_colors
      end

      def build_multiple_choice_radio(response_dic, option, chart_colors, response_cal_hash, vis_identity, res_id, other)
        if other
          response_cal_hash['other'] += 1
          chart_colors['other'] = 'rgb(255, 205, 86)'
        end

        if response_dic['responses'] == option
          response_cal_hash[option] += 1
          if vis_identity == res_id
            chart_colors[option] = 'rgb(255, 205, 86)'
          end
        end
        return response_cal_hash, chart_colors
      end

      def build_multiple_choice_checkbox(responses_arr, option, chart_colors, response_cal_hash, vis_identity, res_id, other)
        if other
          response_cal_hash['other'] += 1
          chart_colors['other'] = 'rgb(255, 205, 86)'
        end
        responses_arr.each do |response|
          if response == option
            response_cal_hash[option] += 1
            if vis_identity == res_id
              chart_colors[option] = 'rgb(255, 205, 86)'
            end
          end
        end
        return [response_cal_hash, chart_colors]
      end
    end
  end
end
