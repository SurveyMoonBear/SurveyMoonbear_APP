# frozen_string_literal: true

module SurveyMoonbear
  class ChangeSurveyState
    def call(survey)
      update_survey_start_flag(survey)
    end

    def update_survey_start_flag(survey)
      Repository::For[survey.class].update_start_flag(survey)
    end
  end
end
