# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return CSV format of responses
    # Usage: Service::TransformStudyResultToCSV.new.call(study_id: "...", params: "...")
    class TransformStudyResultToCSV
      include Dry::Transaction
      include Dry::Monads

      # Item orders of additional data in the last page
      START_TIME_ITEM_ORDER = 0
      END_TIME_ITEM_ORDER = 1
      URL_PARAMS_ITEM_ORDER = 2

      step :responses_data_or_participants_data

      private

      # input { study_id:, params: }
      def responses_data_or_participants_data(input)
        if input[:params]['result_type'] == 'responses'
          res = TransformResponsesToCSV.new.call(launch_id: input[:params]['wave_id'],
                                                 participant_id: input[:params]['participant_id'])
        end
        res.success? ? Success(res.value!) : Failure('Failed to get study responses.')
      rescue StandardError => e
        puts e
        Failure('Failed to get correct result type.')
      end
    end
  end
end
