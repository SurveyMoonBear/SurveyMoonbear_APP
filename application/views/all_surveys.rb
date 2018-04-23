module SurveyMoonbear
  # View object for collection of surveys
  class AllSurveys
    def initialize(all_spreadsheets)
      @all_spreadsheets = all_spreadsheets
    end

    def none?
      @all_spreadsheets.none?
    end

    def any?
      @all_spreadsheets.any?
    end

    def collection
      @all_spreadsheets.map do |spreadsheet|
        Survey.new(spreadsheet)
      end
    end
  end
end
