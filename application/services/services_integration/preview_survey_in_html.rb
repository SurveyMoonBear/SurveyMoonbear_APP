# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # To get survey data from spreadsheet, and transform into HTML for survey preview
  # Usage: PreviewSurveyInHTML.new.call(survey_id: "...", current_account: {...})
  class PreviewSurveyInHTML
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :get_survey_from_spreadsheet
    step :transform_survey_items_to_html

    def get_survey_from_database(survey_id:, current_account:)
      saved_survey = GetSurveyFromDatabase.new.call(survey_id: survey_id)
      Success(saved_survey: saved_survey.value!, current_account: current_account)
    rescue
      Failure('Failed to get survey from database.')
    end

    def get_survey_from_spreadsheet(saved_survey:, current_account:)
      new_survey = GetSurveyFromSpreadsheet.new.call(spreadsheet_id: saved_survey.origin_id, 
                                                     current_account: current_account)
      Success(new_survey: new_survey.value!)
    rescue
      Failure('Failed to get survey from spreadsheet.')
    end

    def transform_survey_items_to_html(new_survey:)
      questions = TransfromSurveyItemsToHTML.new.call(survey: new_survey).value!
      Success(title: new_survey[:title], questions: questions)
    rescue
      Failure('Failed to transform survey items to html.')
    end
  end
end