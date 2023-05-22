# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformSurveyItemsToHTML.new.call(survey: <survey_entity>, random_option: "...", random_seed: "...")
    class TransformSurveyItemsToHTML
      include Dry::Transaction
      include Dry::Monads

      step :group_grid_items
      step :randomize_items_if_needed
      step :build_pages_html_with_items

      private

      # input { survey:, random_option: }
      def group_grid_items(input)
        input[:items_of_pages] = []

        input[:survey].pages.each do |page|
          input[:items_of_pages] << grids_grouping(page.items)
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to group grid items')
      end

      def grids_grouping(items)
        items_with_grids_grouped = []
        same_grids_group = []

        items.each_with_index do |item, i|
          if item.type.include? 'grid'
            same_grids_group << item

            is_last_item_or_next_item_not_same_grid_type = (i + 1 >= items.length || items[i + 1].type != item.type)
            if is_last_item_or_next_item_not_same_grid_type
              items_with_grids_grouped << same_grids_group.clone
              same_grids_group.clear
            end
          else
            items_with_grids_grouped << item
          end
        end

        items_with_grids_grouped
      end

      # input { ..., items_of_pages: }
      def randomize_items_if_needed(input)
        if !input[:random_option].nil? && input[:random_option] != 'none'
          input[:random_seed] = input[:random_seed] ? input[:random_seed].to_i : rand(1000)
          ignored_types = ['Description', 'Section Title', 'Divider']
          input[:items_of_pages].each do |page_items|
            page_items.each_with_index do |item, i|
              random_items_within_grid_group(item, input[:random_seed]) if item.class == Array
              page_items.delete_at(i) if item.class != Array && ignored_types.include?(item.type)
            end

            random_items_within_page(page_items, input[:random_seed])
          end

          if input[:random_option] == 'items_across_pages' && input[:items_of_pages].count > 1
            input[:items_of_pages] = random_items_across_pages(input[:items_of_pages], input[:random_seed])
          end
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to randomize items')
      end

      def random_items_within_grid_group(grid_items, seed)
        grid_items.shuffle!(random: Random.new(seed))
      end

      def random_items_within_page(page_items, seed)
        page_items.shuffle!(random: Random.new(seed))
      end

      def random_items_across_pages(items_of_pages, seed)
        all_items_shuffled = items_of_pages.flatten(1).shuffle(random: Random.new(seed))

        all_items_count = all_items_shuffled.count
        pages_count = items_of_pages.count
        items_num_per_page = all_items_count % pages_count == 0 ? all_items_count / pages_count :
                                                                  all_items_count / pages_count + 1

        paged_items = all_items_shuffled.each_slice(items_num_per_page)
        paged_items.to_a
      end

      def build_pages_html_with_items(input)
        pages_html_arr = input[:items_of_pages].map do |page_items|
          build_items_html_arr(page_items)
        end

        Success(title: input[:survey][:title],
                pages: pages_html_arr,
                random_seed: input[:random_seed])
      rescue StandardError => e
        puts e
        Failure('Failed to transform survey items to html')
      end

      def build_items_html_arr(items)
        items_html_arr = items.map do |item|
          if item.class == Array
            build_grid_questions(item)
          else
            build_individual_question(item)
          end
        end

        items_html_arr
      end

      def build_grid_questions(grids_group_arr)
        case grids_group_arr[0].type
        when 'Multiple choice grid (radio button)'
          build_grid_questions_radio(grids_group_arr)
        # when 'Multiple choice grid (RAM)'
        #   build_grid_questions_ram(grids_group_arr)
        when 'Multiple choice grid (slider)'
          build_grid_questions_slider(grids_group_arr)
        when 'Multiple choice grid (VAS)'
          build_grid_questions_vas(grids_group_arr)
        when 'Multiple choice grid (VAS-slider)'
          build_grid_question_vas_slider(grids_group_arr)
        else
          puts "Sorry, there's no such grid question type: " + grids_group_arr[0].type
        end
      end

      def build_individual_question(item)
        build_interact_var(item)              
        case item.type
        when 'Section Title'
          build_section_title(item)
        when 'Description'
          build_description(item)
        when 'Short answer'
          build_short_answer(item)
        when 'Divider'
          build_divider
        when 'Paragraph Answer'
          build_paragraph_answer(item)
        when 'Single RAM Slider'
          build_single_questions_ram(item)
        when 'Multiple choice (radio button)'
          build_multiple_choice_radio(item)
        when "Multiple choice with 'other' (radio button)"
          build_multiple_choice_radio(item, other=true)
        when 'Multiple choice (checkbox)'
          build_multiple_choice_checkbox(item)
        when "Multiple choice with 'other' (checkbox)"
          build_multiple_choice_checkbox(item, other=true)
        when 'Random code'
          build_random_code(item)
        when 'Jump to page'
          build_jump_page(item)
        else
          puts "Sorry, there's no such individual question type: #{item.type}"
        end
      end

      def build_interact_var(item)
        
        if (!item.description.nil?)&&(item.description.include? '{{') && (item.description.include? '}}')
          var_name = item.description.split('{{')[1].split('}}')[0]
          replace_str = "{{#{var_name}}}"
          var_str = "<span class='#{var_name}__{}' id='#{var_name}__{}'>#{var_name}</span>"
          item.description.gsub!(replace_str, var_str)
          build_interact_var(item)
        elsif (!item.description.nil?)&& (item.description.include? '[[') && (item.description.include? ']]')
          var_name = item.description.split('[[')[1].split(']]')[0]
          
          replace_str = "[[#{var_name}]]"
          slider_ids = var_name.split(",")
          var_str = '';
          slider_ids.each do |id,index|
            if index == 0
              var_str += "<span class='#{id}__[]' id='#{id}__[]'></span>"
            else
              var_str += "<span class='#{id}__[]' id='#{id}__[]' type='hidden'></span>"
            end
          end
          item.description.gsub!(replace_str, var_str)
          build_interact_var(item)
        else
          item
        end
      end

      def build_section_title(item)
        "<h2 class='py-1 mt-5'>#{item.description}</h2>"
      end

      def build_description(item)
        "<div class='my-5'>#{item.description}</div>"
      end

      def build_divider
        "<hr class='my-5'>"
      end

      def build_short_answer(item)
        str = "<div class='form-group mt-5'>"
        if item.required == 1
          str += "<label for='#{item.name}' class='lead'>#{item.description}<span class='text-danger'>*</span></lable>"
          str += "<input type='text' class='form-control required' name='#{item.name}' id='#{item.name}'>"
        else
          str += "<label for='#{item.name}' class='lead'>#{item.description}</lable>"
          str += "<input type='text' class='form-control' name='#{item.name}' id='#{item.name}'>"
        end
        str + '</div>'
      end

      def build_paragraph_answer(item)
        str = "<div class='form-group mt-5'>"
        if item.required == 1
          str += "<label for='#{item.name}' class='lead'>#{item.description}<span class='text-danger'>*</span></label>"
          str += "<textarea class='form-control required' id='#{item.name}' name='#{item.name}' rows='3'></textarea>"
        else
          str += "<label for='#{item.name}' class='lead'>#{item.description}</label>"
          str += "<textarea class='form-control' id='#{item.name}' name='#{item.name}' rows='3'></textarea>"
        end
        str + '</div>'
      end

      def build_multiple_choice_radio(item, other=false)
        str = "<fieldset class='form-group mt-5'>"
        if item.required == 1
          str += "<label id='#{item.name}' class='lead'>#{item.description}<span class='text-danger'>*</span></label>"
        else
          str += "<label id='#{item.name}' class='lead'>#{item.description}</label>"
        end

        if item.options && !item.flow_logic
          item.options.split(',').map(&:strip).each_with_index do |option, index|
            str += "<div class='custom-control custom-radio'>"
            str += "<input type='radio' class='custom-control-input' id='#{item.name}#{index}' name='radio-#{item.name}' value='#{option}'>"
            str += "<label class='custom-control-label' for='#{item.name}#{index}'>#{option}</label>"
            str += '</div>'
          end
        elsif item.options && item.flow_logic
          flow_logic = item.flow_logic.split(',')
          item.options.split(',').map(&:strip).each_with_index do |option, index|
            str += "<div class='custom-control custom-radio'>"
            str += "<input type='radio' class='custom-control-input' id='#{item.name}#{index}__#{flow_logic[index]}' name='radio-#{item.name}' value='#{option}'>"
            str += "<label class='custom-control-label' for='#{item.name}#{index}__#{flow_logic[index]}'>#{option}</label>"
            str += '</div>'
          end
        else
          str += '<p>No options were provided.</p>'
        end

        if other
          str += "<div class='custom-control custom-radio'>"
          str += "<input type='radio' class='custom-control-input other-option' id='#{item.name}_other' name='radio-#{item.name}' value=''>"
          str += "<label class='custom-control-label' for='#{item.name}_other'>other:</label>"
          str += "<input type='text' class='other-text align-middle border-0 ml-2'>"
          str += '</div>'
        end

        if item.required == 1
          str += "<input type='hidden' class='required' name='#{item.name}'>"
        else
          str += "<input type='hidden' name='#{item.name}'>"
        end
        str += '</fieldset>'
      end

      def build_multiple_choice_checkbox(item, other=false)
        str = "<fieldset class='form-group mt-5'>"
        if item.required == 1
          str += "<label id='#{item.name}' class='lead'>#{item.description}<span class='text-danger'>*</span></label>"
        else
          str += "<label id='#{item.name}' class='lead'>#{item.description}</label>"
        end

        if item.options
          item.options.split(',').map(&:strip).each_with_index do |option, index|
            str += "<div class='custom-control custom-checkbox'>"
            str += "<input type='checkbox' class='custom-control-input' id='#{item.name}#{index}' name='checkbox-#{item.name}' value='#{option}'>"
            str += "<label class='custom-control-label' for='#{item.name}#{index}'>#{option}</label>"
            str += '</div>'
          end
        else
          str += "<p>No options were provided.</p>"
        end

        if other
          str += "<div class='custom-control custom-checkbox'>"
          str += "<input type='checkbox' class='custom-control-input other-option' id='#{item.name}_other' name='checkbox-#{item.name}' value=''>"
          str += "<label class='custom-control-label' for='#{item.name}_other'>other:</label>"
          str += "<input type='text' class='other-text align-middle border-0 ml-2'>"
          str += '</div>'
        end

        # Hidden input is for storing the str of joint multiple-checked-answers, and also for keeping update with changes
        str += if item.required == 1
                "<input type='hidden' class='required' name='#{item.name}'>"
              else
                "<input type='hidden' name='#{item.name}'>"
              end
        str += '</fieldset>'
      end

      def build_random_code(item)
        random_code = (rand*(10**15)).round
        str = "<div class='form-group mt-5'>"
        str += "<label for='#{item.name}' class='lead'>#{item.description}</lable>"
        str += "<input type='text' class='form-control' name='#{item.name}' id='#{item.name}' readonly='' value='#{random_code}'>"
        str + '</div>'
      end

      def build_jump_page(item)
        str = "<span hidden name='jump_page_#{item.options}' id='jump_page_#{item.options}'>#{item.options}</span>"
      end

      def build_grid_questions_radio(items)
        str = '<fieldset>'
        str += "<div class='table-responsive'>"
        str += "<table class='table'>"
        str += '<thead><tr>'
        str += "<th scope='col' class='col-5'></th>"

        options = []
        items.each do |item|
          if options.empty? && !item.options.nil?
            options = item.options.split(',').map(&:strip)
            break
          end
        end

        options.each do |option|
          str += "<th scope='col' class='col-1 text-center'>#{option}</th>"
        end
        str += '</tr></thead><tbody>'

        items.each do |item|
          str += "<tr id='#{item.name}'>"
          if item.required == 1
            str += "<td class='lead'>#{item.description}<span class='text-danger'>*</span></td>"
          else
            str += "<td class='lead'>#{item.description}</td>"
          end
          options.each_with_index do |_, index|
            str += "<td class='text-center align-middle'>"
            str += "<div class='form-check'>"
            str += "<input class='form-check-input' type='radio' name='radio-#{item.name}' id='#{item.name}#{index+1}' value='#{index+1}'>"
            str += "<label class='form-check-label' for='#{item.name}#{index}'></label>"
            str += '</div>'
            str += '</td>'
          end

          str += if item.required == 1
                  "<input type='hidden' class='required' name='#{item.name}'>"
                else
                  "<input type='hidden' name='#{item.name}'>"
                end
          str += '</tr>'
        end
        str += '</tbody></table>'
        str += '</div>'
        str += '</fieldset>'
      end

      def build_single_questions_ram(item)
        str = '<fieldset>'
        str += "<table class='table'>"

        min = 0, max = 100, start_point =0
        word_min = '', word_max = ''
        if !item.options.nil?
          values = item.options.split(',').map(&:strip)
          min = values[0]
          max = values[1]
          word_min = values[2] if values[2]
          word_max = values[3] if values[3]
          start_point = values[4] if values[4]
        end
      

        str += '<thead><tr>'
        if item.required == 1
          str += "<td class='w-50 lead'>#{item.description}<span class='text-danger'>*</span></td>"
        else
          str += "<td class='w-50 lead'>#{item.description}</td>"
        end
        str += '</tr>'
        str += "<tr><div class='w-100 row mx-auto'>"
        str += "<div class='col-4 col-sm-2 text-left px-0'>#{word_min}</div>"
        str += "<div class='col-4 offset-4 col-sm-2 offset-sm-8 text-right px-0'>#{word_max}</div>"
        str += '</div></tr></thead>'       
        str += "<tr><td class='w-100 align-middle'><input type='range' class='custom-range ram-slider'  name='ram-#{item.name}' value='#{start_point}' min='#{min}' max='#{max}'></td>"
        str +=  if item.required == 1
                  "<input type='hidden' class='required' name='#{item.name}'>"
                else
                "<input type='hidden' name='#{item.name}'>"
                end
        str += '</tr>'
        str += '</table>'
        str += '</fieldset>'

      end

      def build_grid_questions_slider(items)
        str = '<fieldset>'
        str += "<table class='table'>"

        min = 0, max = 100
        word_min = '', word_max = ''
        items.each do |item|
          if !item.options.nil?
            values = item.options.split(',').map(&:strip)
            min = values[0]
            max = values[1]
            word_min = values[2] if values[2]
            word_max = values[3] if values[3]
            break
          end
        end

        str += '<thead><tr>'
        str += "<th scope='col' class='w-50'></th>"
        str += "<th scope='col' class='w-50'><div class='w-100 row mx-auto'>"
        str += "<div class='col-4 col-sm-2 text-left px-0'>#{word_min}</div>"
        str += "<div class='col-4 offset-4 col-sm-2 offset-sm-8 text-right px-0'>#{word_max}</div>"
        str += '</div></th></tr></thead>'

        items.each do |item|
          str += "<tr id='#{item.name}'>"
          if item.required == 1
            str += "<td class='w-50 lead'>#{item.description}<span class='text-danger'>*</span></td>"
          else
            str += "<td class='w-50 lead'>#{item.description}</td>"
          end
          str += "<td class='w-50 align-middle'><input type='range' class='custom-range ram-slider' id='#{item.name}' name='#{item.name}' value='#{start_point}' min='#{min}' max='#{max}'></td>"
          str +=  if item.required == 1
                    "<input type='hidden' class='required' name='#{item.name}'>"
                  else
                  "<input type='hidden' name='#{item.name}'>"
                  end
          str += '</tr>'
        end
        str += '</table>'
        str += '</fieldset>'
      end

      def build_grid_questions_slider(items)
        str = '<fieldset>'
        str += "<table class='table'>"

        min = 0, max = 100
        word_min = '', word_max = ''
        items.each do |item|
          if !item.options.nil?
            values = item.options.split(',').map(&:strip)
            min = values[0]
            max = values[1]
            word_min = values[2] if values[2]
            word_max = values[3] if values[3]
            break
          end
        end

        str += '<thead><tr>'
        str += "<th scope='col' class='w-50'></th>"
        str += "<th scope='col' class='w-50'><div class='w-100 row mx-auto'>"
        str += "<div class='col-4 col-sm-2 text-left px-0'>#{word_min}</div>"
        str += "<div class='col-4 offset-4 col-sm-2 offset-sm-8 text-right px-0'>#{word_max}</div>"
        str += '</div></th></tr></thead>'

        items.each do |item|
          str += "<tr id='#{item.name}'>"
          if item.required == 1
            str += "<td class='w-50 lead'>#{item.description}<span class='text-danger'>*</span></td>"
          else
            str += "<td class='w-50 lead'>#{item.description}</td>"
          end
          str += "<td class='w-50 align-middle'><input type='range' class='custom-range' id='#{item.name}' name='#{item.name}' min='#{min}' max='#{max}'></td>"
          str += '</tr>'
        end
        str += '</table>'
        str += '</fieldset>'
      end

      def build_grid_questions_vas(items)
        str = '<fieldset>'
        str += "<table class='table'>"

        min = 0, max = 100
        word_min = '', word_max = ''
        items.each do |item|
          if !item.options.nil?
            values = item.options.split(',').map(&:strip)
            min = values[0]
            max = values[1]
            word_min = values[2] if values[2]
            word_max = values[3] if values[3]
          end
        end

        str += '<thead><tr>'
        str += "<th scope='col' class='w-50'></th>"
        str += "<th scope='col' class='w-50'><div class='w-100 row mx-auto'>"
        str += "<div class='col-4 col-sm-2 text-left px-0'>#{word_min}</div>"
        str += "<div class='col-4 offset-4 col-sm-2 offset-sm-8 text-right px-0'>#{word_max}</div>"
        str += '</div></th></tr></thead>'

        items.each do |item|
          str += '<tr>'
          if item.required == 1
            str += "<td class='w-50 lead'>#{item.description}<span class='text-danger'>*</span></td>"
          else
            str += "<td class='w-50 lead'>#{item.description}</td>"
          end
          str += "<td class='w-50 align-middle'><input type='range' class='custom-range vas-unclicked' name='vas-#{item.name}' min='#{min}' max='#{max}'></td>"

          str += if item.required == 1
                   "<input type='hidden' class='required' name='#{item.name}'>"
                 else
                   "<input type='hidden' name='#{item.name}'>"
                 end
          str += '</tr>'
        end
        str += '</table>'
        str += '</fieldset>'
      end
    end
  end
end
