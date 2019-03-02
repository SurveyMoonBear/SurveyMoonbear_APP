# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of question HTML strings
    # Usage: Service::TransformSurveyItemsToHTML.new.call(survey_id: "...")
    class TransformSurveyItemsToHTML
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database
      step :build_pages_html_with_question_items

      private

      # input { survey_id: }
      def get_survey_from_database(input)
        db_survey = GetSurveyFromDatabase.new.call(survey_id: input[:survey_id])

        if db_survey.success?
          input[:db_survey] = db_survey.value!
          Success(input)
        else
          Failure(db_survey.failure)
        end
      end

      # input { ..., db_survey: }
      def build_pages_html_with_question_items(input)
        pages_html_arr = input[:db_survey].pages.map do |page|
          build_pages_html_arr(page)
        end

        Success(title: input[:db_survey][:title], pages: pages_html_arr)
      rescue StandardError => e
        puts e
        Failure('Failed to transform survey items to html')
      end

      def build_pages_html_arr(page)
        q_arr = []
        grid_arr = []
        items = page.items
        items.each_with_index.map do |item, i|
          if item.type.include? 'grid'
            grid_arr.push(item)
            if i + 1 >= items.length || items[i + 1].type != item.type
              q_arr.push(build_grid_questions(grid_arr))
              grid_arr.clear
            end
          else
            q_arr.push(build_individual_question(item))
          end
        end
        q_arr
      end

      def build_individual_question(item)
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
        when 'Multiple choice (radio button)'
          build_multiple_choice_radio(item)
        when 'Multiple choice (checkbox)'
          build_multiple_choice_checkbox(item)
        when 'Random code'
          build_random_code(item)
        else
          puts "Sorry, there's no such question type."
        end
      end

      private

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

      def build_multiple_choice_radio(item)
        str = "<fieldset class='form-group mt-5'>"
        if item.required == 1
          str += "<label id='#{item.name}' class='lead'>#{item.description}<span class='text-danger'>*</span></label>"
        else
          str += "<label id='#{item.name}' class='lead'>#{item.description}</label>"
        end

        if item.options
          item.options.split(',').map(&:strip).each_with_index do |option, index|
            str += "<div class='custom-control custom-radio'>"
            str += "<input type='radio' class='custom-control-input' id='#{item.name}#{index}' name='radio-#{item.name}' value='#{option}'>"
            str += "<label class='custom-control-label' for='#{item.name}#{index}'>#{option}</label>"
            str += '</div>'
          end
        else
          str += "<p>No options were provided.</p>"
        end

        if item.required == 1
          str += "<input type='hidden' class='required' name='#{item.name}'>"
        else
          str += "<input type='hidden' name='#{item.name}'>"
        end 
        str += '</fieldset>'
      end

      def build_multiple_choice_checkbox(item)
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

      def build_grid_questions(grid_arr)
        case grid_arr[0].type
        when 'Multiple choice grid (radio button)'
          build_grid_questions_radio(grid_arr)
        when 'Multiple choice grid (slider)'
          build_grid_questions_slider(grid_arr)
        when 'Multiple choice grid (VAS)'
          build_grid_questions_vas(grid_arr)
        when 'Multiple choice grid (VAS-slider)'
          build_grid_question_vas_slider(grid_arr)
        else
          puts "Sorry, there's no such question type."
        end
      end

      def build_grid_questions_radio(items)
        str = '<fieldset>'
        str += "<div class='table-responsive'>"
        str += "<table class='table'>"
        str += '<thead><tr>'
        str += "<th scope='col' class='col-5'></th>"

        options = items[0].options.split(',').map(&:strip)
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

      def build_grid_questions_slider(items)
        str = '<fieldset>'
        str += "<table class='table'>"

        if items[0].options.nil?
          min = 0
          max = 100
        else
          min_max = items[0].options.split(',').map(&:strip)
          min = min_max[0]
          max = min_max[1]
          if min_max[2]
            word_min = min_max[2]
            word_max = min_max[3]
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

        if items[0].options.nil?
          min = 0
          max = 100
        else
          min_max = items[0].options.split(',').map(&:strip)
          min = min_max[0]
          max = min_max[1]
          if min_max[2]
            word_min = min_max[2]
            word_max = min_max[3]
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
