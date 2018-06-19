# frozen_string_literal: true

module SurveyMoonbear
  class UpdateSurveyData
    def call(survey, launch_id)
      store_survey_into_database(survey, launch_id)
    end

    def store_survey_into_database(survey, launch_id)
      Repository::For[survey.class].update_from(survey, launch_id)
    end
  end
end
