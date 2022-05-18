require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return graph array:
    # [item_data.page, item_data.graph_title, item_data.chart_type, response_cal_hash, labels, chart_colors]
    # Usage: Service::MapSurveyResponsesAndItems.new.call(item_data: "...", source: "...",)
    class MapSurveyResponsesAndItems
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_responses
      step :organize_all_responses
      step :generate_default_options_and_cal
      step :return_graph_result

      private

      # input{ item_data: ..., source: ...}
      def get_survey_responses(input)
        survey = Repository::For[Entity::Survey].find_title(input[:source].source_name)
        launch = Repository::For[Entity::Launch].find_id(survey.launch_id)
        input[:all_responses] = launch.responses

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get survey responses from db.')
      end

      # input{ all_responses: ..., item_data: ..., source: ...}
      def organize_all_responses(input)
        input[:item_responses] = {}
        input[:item_options] = []
        item_all_responses = [] # only response

        input[:all_responses].each do |res_obj|
          if !res_obj.item_data.nil?
          question = JSON.parse(res_obj.item_data)
            if question['name'] == input[:item_data].question
              item_all_responses.append(res_obj.response)
              input[:item_responses]['type'] = question['type']
              input[:item_options] = question['options'] if !question['options'].nil?
            end
          end
        end
        input[:item_responses]['responses'] = item_all_responses
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to organize survey responses.')
      end

      # input{ item_responses:..., item_options: ..., all_responses: ..., item_data: ..., ...}
      def generate_default_options_and_cal(input)
        response_cal_hash = {}
        chart_colors = {}
        if !input[:item_options].empty?
          options = input[:item_options].gsub("\n", '')
          options = options.split(',')
          options.each do |option|
            response_cal_hash[option] = 0
            chart_colors[option] = 'rgb(54, 162, 235)'
          end

          input[:response_cal_hash], input[:chart_colors] = cal_individual_question(input[:item_responses],
                                                                                    options,
                                                                                    chart_colors,
                                                                                    response_cal_hash)
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to generate default options or calculate reponses.')
      end

      # input{ response_cal_hash:..., chart_colors: ..., item_data: ..., ...}
      def return_graph_result(input)
        graph_val = []
        graph_val.append(input[:item_data].page,
                         input[:item_data].graph_title,
                         input[:item_data].chart_type,
                         input[:response_cal_hash].values,
                         input[:chart_colors].keys,
                         input[:chart_colors].values,
                         input[:item_data].legend)
        Success(graph_val)
      rescue StandardError => e
        puts e
        Failure('Failed to return graph result.')
      end

      def cal_individual_question(response_dic, options, chart_colors, response_cal_hash)
        response_cal_hash, chart_colors =
          case response_dic['type']
          when 'Multiple choice (radio button)'
            cal_multiple_choice_radio(response_dic, chart_colors, response_cal_hash)
          when "Multiple choice with 'other' (radio button)"
            cal_multiple_choice_radio_with_other(response_dic, chart_colors, response_cal_hash)
          when 'Multiple choice (checkbox)'
            responses_arr = []
            response_dic['responses'].each do |responses_perperson|
              responses_arr += responses_perperson.split(', ')
            end
            cal_multiple_choice_checkbox(responses_arr, chart_colors, response_cal_hash)
          when "Multiple choice with 'other' (checkbox)"
            responses_arr = []
            response_dic['responses'].each do |responses_perperson|
              responses_arr += responses_perperson.split(', ')
            end

            cal_multiple_choice_checkbox_with_other(responses_arr, chart_colors, response_cal_hash)
          when 'Multiple choice grid (radio button)'
            temp_option = {}
            options.each_with_index do |option, i|
              temp_option["#{i+1}"] = option # {'1'=>'Strongly Disagre', '2'=>'Disgree'...}
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

        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_checkbox(responses_arr, chart_colors, response_cal_hash)
        responses_hash = responses_arr.tally
        response_cal_hash.each_key do |key|
          response_cal_hash[key] = responses_hash[key]
        end

        [response_cal_hash, chart_colors]
      end

      def cal_multiple_choice_checkbox_with_other(responses_arr, chart_colors, response_cal_hash)
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

        [response_cal_hash, chart_colors]
      end

      def cal_choice_grid(response_dic, temp_option, chart_colors, response_cal_hash)
        responses_hash = response_dic['responses'].sort.tally
        responses_hash.each_key do |key|
          response_cal_hash[temp_option[key]] = responses_hash[key]
        end

        [response_cal_hash, chart_colors]
      end
    end
  end
end
