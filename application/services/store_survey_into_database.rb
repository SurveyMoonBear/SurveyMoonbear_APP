module SurveyMoonbear
  class StoreSurveyIntoDatabase
    def call(survey)
      store_survey_into_database(survey)
    end

    def store_survey_into_database(survey)
      Repository::For[survey.class].update_from(survey)
    end
  end
end
