module SurveyMoonbear
  class CheckRequiredAnswers
    def call(survey_id, params)
      survey = get_survey_from_database(survey_id)
      items_required = get_required_items(survey)
      check_params_value(items_required, params)
    end

    def get_survey_from_database(survey_id)
      Repository::For[Entity::Survey].find_id(survey_id)
    end

    def get_required_items(survey)
      items_required = []
      survey.pages.each do |page|
        page.items.each do |item|
          next unless item.required == 1
          items_required.push(item)
        end
      end
      items_required
    end

    def check_params_value(items_required, params)
      items_required.each do |item|
        return false if params[item.name].nil?
      end
      true
    end
  end
end
