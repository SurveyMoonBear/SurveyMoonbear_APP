# frozen_string_literal: true

module SurveyMoonbear
  # Return an entity of survey from database
  class GetSurveyFromDatabase
    def call(survey_id)
      get_survey_from_database(survey_id)
    end

    def get_survey_from_database(survey_id)
      Repository::For[Entity::Survey].find_origin_id(survey_id)
    end
  end
end
