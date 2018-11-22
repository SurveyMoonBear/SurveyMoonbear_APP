# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # Return a updated launch
  # Usage: CloseSurvey.new.call(survey_id: "...")
  class CloseSurvey
    include Dry::Transaction
    include Dry::Monads

    step :get_survey_from_database
    step :change_survey_state
    step :change_launch_state

    def get_survey_from_database(survey_id:)
      saved_survey = GetSurveyFromDatabase.new.call(survey_id: survey_id)
      Success(saved_survey: saved_survey.value!)
    rescue
      Failure('Failed to get survey from database.')
    end

    def change_survey_state(saved_survey:)
      db_survey = Repository::For[saved_survey.class].update_state(saved_survey)
      Success(db_survey: db_survey)
    rescue
      Failure('Failed to change survey state to closed.')
    end

    def change_launch_state(db_survey:)
      db_launch = Repository::For[Entity::Launch].find_id(db_survey.launch_id)
      updated_launch = Repository::For[db_launch.class].update_state(db_launch)
      Success(updated_launch)
    rescue
      Failure('Failed to change launch state to closed.')
    end
  end
end
