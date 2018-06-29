# frozen_string_literal: true

module SurveyMoonbear
  # Return a updated survey
  class StartSurvey
    def call(survey)
      store_survey_into_database_and_launch(survey)
    end

    def store_survey_into_database_and_launch(survey)
      Repository::For[survey.class].add_launch(survey)
    end
  end
end
