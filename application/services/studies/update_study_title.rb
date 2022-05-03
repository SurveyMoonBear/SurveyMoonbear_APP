# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted study entity of new title
    # Usage: Service::UpdateStudyTitle.new.call(current_account: {...}, study_id: "...", new_title: "...")
    class UpdateStudyTitle
      include Dry::Transaction
      include Dry::Monads

      step :update_study_title

      private

      # input { ... }
      def update_study_title(input)
        updated_study = Repository::For[Entity::Study].update_title(input[:study_id], input[:new_title])
        Success(updated_study)
      rescue
        Failure('Failed to update study title in database')
      end
    end
  end
end
