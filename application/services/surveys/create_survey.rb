# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::CreateSurvey.new.call(config: <config>, current_account: {...}, title: "...")
    class CreateSurvey
      include Dry::Transaction
      include Dry::Monads

      step :copy_sample_spreadsheet

      private

      # input { config:, current_account:, title: }
      def copy_sample_spreadsheet(input)
        new_survey = CopySurvey.new.call(config: input[:config],
                                         current_account: input[:current_account],
                                         spreadsheet_id: input[:config].SAMPLE_FILE_ID,
                                         title: input[:title])
        if new_survey.success?
          Success(new_survey.value!)
        else
          Failure(new_survey.failure)
        end
      end
    end
  end
end
