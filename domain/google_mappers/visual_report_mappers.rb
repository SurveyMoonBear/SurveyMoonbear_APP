# frozen_string_literal: true

require_relative 'account_mapper'
require_relative 'source_mapper'

module SurveyMoonbear
  module Google
    # Data Mapper object for Google's spreadsheet
    class VisualReportMapper
      def initialize(gateway)
        @gateway = gateway
      end

      def load(spreadsheet_id, owner)
        report = {}
        report[:data] = @gateway.survey_data(spreadsheet_id) # survey_data = spreadsheet data
        report[:owner] = owner
        build_entity(report)
      end

      def build_entity(report)
        DataMapper.new(report).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(report)
          @report = report
          @account_mapper = AccountMapper.new
        end

        def build_entity
          SurveyMoonbear::Entity::VisualReport.new(
            id: nil,
            owner: owner,
            origin_id: origin_id,
            title: title,
            created_at: nil,
            state: nil
          )
        end

        def owner
          @account_mapper.load(@report[:owner])
        end

        def origin_id
          @report[:data]['spreadsheetId']
        end

        def title
          @report[:data]['properties']['title']
        end
      end
    end
  end
end
