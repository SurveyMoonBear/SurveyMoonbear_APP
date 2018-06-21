module SurveyMoonbear
  class TransfromSurveyItemsToHTML
    def call(survey)
      survey.pages.map do |page|
        build_questions(page)
      end
    end

    def build_questions(page)
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
      when 'Paragraph Answer'
        build_paragraph_answer(item)
      when 'Multiple choice (radio button)'
        build_multiple_choice_radio(item)
      when 'Multiple choice (checkbox)'
        build_multiple_choice_checkbox(item)
      else
        puts "Sorry, there's no such question type."
      end
    end

    private

    def build_section_title(item)
      "<h2 class='bg-light py-1 pl-1 mt-5'>#{item.description}</h2>"
    end

    def build_description(item)
      "<p class='lead'>#{item.description}</p>"
    end

    def build_short_answer(item)
      str = "<div class='form-group'>"
      str += "<label for='#{item.name}' class='lead'>#{item.description}</lable>"
      str += "<input type='text' class='form-control' name='#{item.name}' id='#{item.name}'>"
      str + '</div>'
    end

    def build_paragraph_answer(item)
      str = "<div class='form-group'>"
      str += "<label for='#{item.name}' class='lead'>#{item.description}</label>"
      str += "<textarea class='form-control' id='#{item.name}' name='#{item.name}' rows='3'></textarea>"
      str + '</div>'
    end

    def build_multiple_choice_radio(item)
      str = "<fieldset class='form-group'>"
      str += "<label id='#{item.name}' class='lead'>#{item.description}</label>"

      item.options.split(',').each_with_index do |option, index|
        str += "<div class='custom-control custom-radio'>"
        str += "<input type='radio' class='custom-control-input' id='#{item.name}#{index}' name='#{item.name}' value='#{option}'>"
        str += "<label class='custom-control-label' for='#{item.name}#{index}'>#{option}</label>"
        str += '</div>'
      end
      str += '</fieldset>'
    end

    def build_multiple_choice_checkbox(item)
      str = "<fieldset class='form-group'>"
      str += "<label id='#{item.name}' class='lead'>#{item.description}</label>"

      item.options.split(',').each_with_index do |option, index|
        str += "<div class='custom-control custom-checkbox'>"
        str += "<input type='checkbox' class='custom-control-input' id='#{item.name}#{index}' name='#{item.name}' value='#{option}'>"
        str += "<label class='custom-control-label' for='#{item.name}#{index}'>#{option}</label>"
        str += '</div>'
      end
      str += '</fieldset>'
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

      options = items[0].options.split(',')
      options.each do |option|
        str += "<th scope='col' class='col-1 text-center'>#{option}</th>"
      end
      str += '</tr></thead><tbody>'

      items.each do |item|
        str += "<tr id='#{item.name}'>"
        str += "<td class='lead'>#{item.description}</td>"
        options.each_with_index do |_, index|
          str += "<td class='text-center align-middle'>"
          str += "<div class='form-check'>"
          str += "<input class='form-check-input' type='radio' name='#{item.name}' id='#{item.name}#{index+1}' value='#{index+1}'>"
          str += "<label class='form-check-label' for='#{item.name}#{index}'></label>"
          str += '</div>'
          str += '</td>'
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

      min_max = items[0].options.split(',')
      min = min_max[0]
      max = min_max[1]

      items.each do |item|
        str += "<tr id='#{item.name}'>"
        str += "<td class='w-50 lead'>#{item.description}</td>"
        str += "<td class='w-50'><input type='range' class='custom-range' id='#{item.name}' min='#{min}' max='#{max}'></td>"
        str += '</tr>'
      end
      str += '</table>'
      str += '</fieldset>'
    end

    def build_grid_questions_vas(items)
      str = '<fieldset>'
      str += "<table class='table'>"

      min_max = items[0].options.split(',')
      min = min_max[0]
      max = min_max[1]

      items.each do |item|
        str += '<tr>'
        str += "<td class='w-50 lead'>#{item.description}</td>"
        str += "<td class='w-50'><input type='range' class='custom-range vas-unclicked' id='#{item.name}' min='#{min}' max='#{max}'></td>"
        str += '</tr>'
      end
      str += '</table>'
      str += '</fieldset>'
    end
  end
end
