# frozen_string_literal: true

module SurveyMoonbear
  # Return a updated launch
  class CloseSurvey
    def call(survey)
      db_survey = change_survey_state(survey)
      change_launch_state(db_survey)
    end

    def change_survey_state(survey)
      Repository::For[survey.class].update_state(survey)
    end

    def change_launch_state(db_survey)
      db_launch = Repository::For[Entity::Launch].find_id(db_survey.launch_id)
      Repository::For[db_launch.class].update_state(db_launch)
    end
  end
end
