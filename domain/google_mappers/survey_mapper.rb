# frozen_string_literal: true

require_relative 'account_mapper.rb'
require_relative 'page_mapper.rb'

module SurveyMoonbear
  module Google
    # Data Mapper object for Google's spreadsheet
    class SurveyMapper
      def initialize(gateway)
        @gateway = gateway
      end

      def load(spreadsheet_id, owner)
        survey = {}
        survey[:data] = @gateway.survey_data(spreadsheet_id)
        survey[:owner] = owner
        build_entity(survey)
      end

      def build_entity(survey)
        DataMapper.new(survey, @gateway).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(survey, gateway)
          @survey = survey
          @account_mapper = AccountMapper.new
          @page_mapper = PageMapper.new(gateway)
        end

        def build_entity
          SurveyMoonbear::Entity::Survey.new(
            id: nil,
            owner: owner,
            launch_id: nil,
            origin_id: origin_id,
            title: title,
            created_at: nil,
            state: nil,
            options: nil,
            pages: pages,
            launches: nil
          )
        end

        def owner
          @account_mapper.load(@survey[:owner])
        end

        def origin_id
          @survey[:data]['spreadsheetId']
        end

        def title
          @survey[:data]['properties']['title']
        end

        def pages
          @page_mapper.load_several(origin_id, @survey[:data]['sheets'])
        end
      end
    end
  end
end
