# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformDBSurveyToHTML.new.call(survey_id: "...", random_seed: "...")
    class TransformDBSurveyToHTML
      include Dry::Transaction
      include Dry::Monads

      step :get_survey_from_database
      step :transform_survey_items_to_html

      private

      # input { survey_id: }
      def get_survey_from_database(input)
        db_survey = GetSurveyFromDatabase.new.call(survey_id: input[:survey_id])

        if db_survey.success?
          input[:db_survey] = db_survey.value!
          Success(input)
        else
          Failure(db_survey.failure)
        end
      end

      # input { ..., db_survey: }
      def transform_survey_items_to_html(input)
        random_option = JSON.parse(input[:db_survey].options)['random']

        transform_result = TransformSurveyItemsToHTML.new.call(survey: input[:db_survey],
                                                               random_option: random_option,
                                                               random_seed: input[:random_seed])

        if transform_result.success?
          Success(title: transform_result.value![:title], 
                  pages: transform_result.value![:pages],
                  random_seed: transform_result.value![:random_seed])
        else
          Failure(transform_result.failure)
        end
      end
    end
  end
end