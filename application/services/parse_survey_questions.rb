module SurveyMoonbear
  class ParseSurveyQuestions
    def call(question_details)
      questions = remove_data_header(question_details)
      build_questions(questions)
    end

    def remove_data_header(question_details)
      question_details.shift
      question_details
    end

    def build_questions(questions)
      q_arr = []
      grid_arr = []
      questions.each_with_index.map do |question, i|
        if question[0].include? 'grid'
          grid_arr.push(question)
          if i + 1 >= questions.length || questions[i + 1][0] != question[0]
            q_arr.push(build_grid_questions(grid_arr))
            grid_arr.clear
          end
        else
          q_arr.push(build_individual_question(question))
        end
      end
      q_arr
    end

    def build_individual_question(question)
      case question[0]
      when 'Section Title'
        build_section_title(question)
      when 'Description'
        build_description(question)
      when 'Short answer'
        build_short_answer(question)
      when 'Paragraph Answer'
        build_paragraph_answer(question)
      when 'Multiple choice (radio button)'
        build_multiple_choice_radio(question)
      when 'Multiple choice (checkbox)'
        build_multiple_choice_checkbox(question)
      else
        puts "Sorry, there's no such question type."
      end
    end

    private

    def build_section_title(question)
      "<h2>#{question[2]}</h2>"
    end

    def build_description(question)
      "<p>#{question[2]}</p>"
    end

    def build_short_answer(question)
      str = "<div class='form-group'>"
      str << "<label for='#{question[1]}'>#{question[2]}</lable>"
      str << "<input type='text' class='form-control' id='#{question[1]}'>"
      str << '</div>'
    end

    def build_paragraph_answer(question)
      str = "<div class='form-group'>"
      str << "<label for='#{question[1]}'>#{question[2]}</label>"
      str << "<textarea class='form-control' id='#{question[1]}' rows='3'></textarea>"
      str << '</div>'
    end

    def build_multiple_choice_radio(question)
      str = "<fieldset class='form-group'>"
      str << "<label>#{question[2]}</label>"

      question[4].split(',').each_with_index do |option, index|
        str << "<div class='custom-control custom-radio'>"
        str << "<input type='radio' class='custom-control-input' id='#{question[1]}#{index}' name='#{question[1]}'>"
        str << "<label class='custom-control-label' for='#{question[1]}#{index}'>#{option}</label>"
        str << '</div>'
      end
      str << '</fieldset>'
    end

    def build_multiple_choice_checkbox(question)
      str = "<fieldset class='form-group'>"
      str << "<label>#{question[2]}</label>"

      question[4].split(',').each_with_index do |option, index|
        str << "<div class='custom-control custom-checkbox'>"
        str << "<input type='checkbox' class='custom-control-input' id='#{question[1]}#{index}' name='#{question[1]}'>"
        str << "<label class='custom-control-label' for='#{question[1]}#{index}'>#{option}</label>"
        str << '</div>'
      end
      str << '</fieldset>'
    end

    def build_grid_questions(grid_arr)
      case grid_arr[0][0]
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

    def build_grid_questions_radio(questions)
      str = '<fieldset>'
      str << "<table class='table'>"
      str << '<tr>'
      str << "<th scope='col' class='col-5'></th>"

      options = questions[0][4].split(',')
      options.each do |option|
        str << "<th scope='col' class='col-1 text-center'>#{option}</th>"
      end
      str << '</tr>'

      questions.each do |question|
        str << '<tr>'
        str << "<td>#{question[2]}</td>"
        options.each_with_index do |_, index|
          str << "<td class='text-center'>"
          str << "<div class='form-check'>"
          str << "<input class='form-check-input' type='radio' name='#{question[1]}' id='#{question[1]}#{index}' value='#{index}'>"
          str << "<label class='form-check-label' for='#{question[1]}#{index}'></label>"
          str << '</div>'
          str << '</td>'
        end
        str << '</tr>'
      end
      str << '</table>'
      str << '</fieldset>'
    end

    def build_grid_questions_slider(questions)
      str = '<fieldset>'
      str << "<table class='table'>"

      min_max = questions[0][4].split(',')
      min = min_max[0]
      max = min_max[1]

      questions.each do |question|
        str << '<tr>'
        str << "<td class='w-50'>#{question[2]}</td>"
        str << "<td class='w-50'><input type='range' class='custom-range slider' id='#{question[1]}' min='#{min}' max='#{max}'></td>"
        str << '</tr>'
      end
      str << '</table>'
      str << '</fieldset>'
    end

    def build_grid_questions_vas(questions)
      str = '<fieldset>'
      str << "<table class='table'>"

      min_max = questions[0][4].split(',')
      min = min_max[0]
      max = min_max[1]

      questions.each do |question|
        str << '<tr>'
        str << "<td class='w-50'>#{question[2]}</td>"
        str << "<td class='w-50'><input type='range' class='custom-range vas-unclicked' id='#{question[1]}' min='#{min}' max='#{max}'></td>"
        str << '</tr>'
      end
      str << '</table>'
      str << '</fieldset>'
    end
  end
end
