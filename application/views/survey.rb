# frozen_string_literal: true

module SurveyMoonbear
  module Views
    # View object for a single survey
    class Survey
      def initialize(spreadsheet)
        @spreadsheet = spreadsheet
      end

      def owner
        @spreadsheet.owner.username
      end

      def title
        @spreadsheet.title
      end
    end
  end
end
