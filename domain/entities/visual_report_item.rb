# frozen_string_literal: true

module SurveyMoonbear
  module Entity
    # Domain entity object for any visual_report
    class VisualReportItem < Dry::Struct
      include Dry.Types
      attribute :id, Integer.optional
      attribute :spreadsheet_id, Strict::String
      attribute :page, Integer
      attribute :graph_title, Strict::String
      attribute :data_source, String
      attribute :question, Strict::String
      attribute :chart_type, Strict::String
    end
  end
end
