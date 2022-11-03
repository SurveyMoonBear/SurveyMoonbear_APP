# frozen_string_literal: true

# module SurveyMoonbear
module Views
  # View for a visual report html
  class TextReport
    def initialize(report)
      @report = report
    end

    def title
      @report.title
    end

    def score
      @report.score
    end
  end
end
