# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return data or a HTML page?
    # Usage: Service::TransformSheetsResponsesToChart.new.call(survey_id: "...", spreadsheet_id: "...", access_token: "...", launch_id: "...")
    class TransformSheetsResponsesToChart
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database
      step :chart_to_hash_array
      step :get_launch_from_database
      step :questions_to_hash_array
      step :calculate_responses_times
      step :transform_hashes_to_array
      step :transform_reponses_to_html

      private

      # input { survey_id: }
      def get_survey_from_database(input)
        db_survey = GetSurveyFromDatabase.new.call(survey_id: input[:survey_id])
        if db_survey.success?
          input[:pages] = db_survey.value!.pages
          Success(input)
        else
          Failure(db_survey.failure)
        end
      end

      def chart_to_hash_array(input)
        chart_hashes = {}
        input[:pages].each do |page|
          page.items.each do |item|
            chart_hashes[item.name] = item.visualization unless item.visualization.nil?
          end
        end
        input[:chart_hashes] = chart_hashes # {"age_num"=>"bar", "social_website"=>"bar", "needs"=>"pie"}
        input[:chart_types] = chart_hashes.values.map { |val| val } # ["bar", "bar", "pie"]
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to store chart hashes')
      end

      # input { launch_id: }
      def get_launch_from_database(input)
        launch = Repository::For[Entity::Launch].find_id(input[:launch_id])

        input[:response_objs] = launch.responses
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get launch from database')
      end

      def questions_to_hash_array(input)
        labels_hashes = {}
        input[:response_objs].each do |res_obj|
          if !res_obj.item_data.nil?
            item_data = JSON.parse(res_obj.item_data)
            if !item_data['options'].nil?
              options_name = item_data['name']
              options_str = item_data['options']
              options_arr = options_str.split(',').map(&:strip)
              labels_hashes[options_name] = { 'options': options_arr }
            end
          end
        end

        input[:question_labels] = labels_hashes # input[:question_labels]["age_num"][1][:options][0] => "10~20"
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to organize questions to hash array.')
      end

      def calculate_responses_times(input)
        response_cal_hashes = {}
        response_cal_arr = []
        input[:response_objs].each do |res_obj|
          if !res_obj.item_data.nil?
            item_data = JSON.parse(res_obj.item_data)
            if !res_obj.response.nil?

              response = res_obj.response
              option_name = item_data['name']
              next unless input[:chart_hashes].key?(option_name) # input[:chart_hashes].keys include option_name?

              response_cal_hashes[option_name] = {} if response_cal_hashes[option_name].nil?

              response_cal_hashes[option_name]['chart_type'] = input[:chart_hashes][option_name]
              response_cal_hashes[option_name]['options'] = {} if response_cal_hashes[option_name]['options'].nil?
              options_arr = input[:question_labels][option_name][:options]
              temp_arr =
                if item_data['type'].include? 'Multiple choice grid'
                  multi_choice_grid_question_compute(response_cal_hashes, option_name, response, options_arr)
                else
                  multi_choice_question_compute(response_cal_hashes, option_name, response, options_arr)
                end
              response_cal_arr.append(temp_arr)
            end
          end
        end

        input[:chart_names] = response_cal_hashes.keys
        # input[:chart_datas] = response_cal_arr
        input[:response_cal_hashes] = response_cal_hashes
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to calculate the responses.')
      end

      # input { ..., response_cal_hashes: }
      def transform_hashes_to_array(input)
        all_options_arr = []
        all_options_count = []

        input[:chart_names].each do |name|
          all_options_arr.append(input[:response_cal_hashes][name]['options'].keys)
          all_options_count.append(input[:response_cal_hashes][name]['options'].values)
        end

        input[:chart_labels] = all_options_arr
        input[:chart_datas] = all_options_count
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to transform hashes to array.')
      end

      # input { ..., response_cal_hashes: }
      def transform_reponses_to_html(input)
        transform_result = TransformResponsesToHTMLWithChart.new.call(responses_to_chart: input[:response_cal_hashes])

        if transform_result.success?
          Success(chart_names: input[:chart_names],
                  chart_labels: input[:chart_labels],
                  chart_types: input[:chart_types],
                  chart_datas: input[:chart_datas],
                  canvas_html: transform_result.value!)
        else
          Failure(transform_result.failure)
        end
      end

      # 1, ["strongly disagree","disagree","neutral","agree","strongly agree"]
      def multi_choice_grid_question_compute(response_cal_hashes, option_name, response, options_arr)
        response_to_str = options_arr[response.to_i - 1]
        options_arr.each do |option| # "strongly disagree","disagree","neutral","agree","strongly agree"
          response_cal_hashes[option_name]['options'][option] = 0 if response_cal_hashes[option_name]['options'][option].nil?
          if response_to_str == option
            response_cal_hashes[option_name]['options'][option] += 1
          end
        end
        response_cal_hashes[option_name]['options'].values # [2, 0, 3, 1, 0]
      end

      def multi_choice_question_compute(response_cal_hashes, option_name, response, options_arr)
        options_arr.each do |option|
          response_cal_hashes[option_name]['options'][option] = 0 if response_cal_hashes[option_name]['options'][option].nil?
          if response == option
            response_cal_hashes[option_name]['options'][option] += 1
          end
        end
        response_cal_hashes[option_name]['options'].values
      end
    end
  end
end
