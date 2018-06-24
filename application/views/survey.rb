# frozen_string_literal: true

module SurveyMoonbear
  module Views
    # View object for a single repo's Github project
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

      # def contributors
      #   @repo.contributors.map(&:username).join(', ')
      # end
    end
  end
end
