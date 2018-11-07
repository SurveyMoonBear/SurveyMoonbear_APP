# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  # Return a updated launch
  # Usage: CloseSurvey.new.call(survey: <survey_entity>)
  class CloseSurvey
    include Dry::Transaction
    include Dry::Monads

    step :change_survey_state
    step :change_launch_state

    def change_survey_state(survey:)
      db_survey = Repository::For[survey.class].update_state(survey)
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
