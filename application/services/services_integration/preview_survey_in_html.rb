require 'dry/transaction'

module SurveyMoonbear
  class PreviewSurveyInHTML
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :get_survey_from_spreadsheet
    step :transform_survey_items_to_html

    def get_survey_from_database(survey_id)
      saved_survey = GetSurveyFromDatabase.new.call(survey_id)
      Success(saved_survey)
    rescue
      Failure('Failed to get survey from database.')
    end

    def get_survey_from_spreadsheet(saved_survey, current_account)
      new_survey = GetSurveyFromSpreadsheet.new(current_account)
                                           .call(saved_survey.origin_id)
      Success(new_survey)
    rescue
      Failure('Failed to get survey from spreadsheet.')
    end

    def transform_survey_items_to_html(new_survey)
      questions = TransfromSurveyItemsToHTML.new.call(new_survey)
      Success({ title: new_survey[:title], questions: questions })
    rescue
      Failure('Failed to transform survey items to html.')
    end
  end
end
