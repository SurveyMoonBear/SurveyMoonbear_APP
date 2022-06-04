# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::CreateSurvey.new.call(config: <config>, current_account: {...}, title: "...", study_id: "...")
    class CreateSurvey
      include Dry::Transaction
      include Dry::Monads

      step :copy_sample_spreadsheet
      step :store_belongs_study

      private

      # input { config:, current_account:, title:, study_id: }
      def copy_sample_spreadsheet(input)
        new_survey = CopySurvey.new.call(config: input[:config],
                                         current_account: input[:current_account],
                                         spreadsheet_id: input[:config].SAMPLE_FILE_ID,
                                         title: input[:title])
        if new_survey.success?
          input[:survey] = new_survey.value!
          Success(input)
        else
          Failure(new_survey.failure)
        end
      end

      # input { ..., survey: }
      def store_belongs_study(input)
        unless input[:study_id].nil?
          Repository::For[Entity::Study].add_survey(input[:study_id], input[:survey].id)
        end

        Success(input[:survey])
      rescue StandardError => e
        puts e
        Failure('Failed to add related study in to survey.')
      end
    end
  end
end
