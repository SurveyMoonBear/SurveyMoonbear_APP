require_relative 'item_mapper.rb'

module SurveyMoonbear
  # Data Structure for Survey Page
  module Google
    # Data Mapper for sheet
    class PageMapper
      def initialize(gateway)
        @gateway = gateway
      end

      def load_several(survey_id, pages_data)
        pages_data.each_with_index.map do |page_data|
          PageMapper.build_entity(survey_id, page_data, @gateway)
        end
      end

      def self.build_entity(survey_id, page_data, gateway)
        DataMapper.new(survey_id, page_data, gateway).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(survey_id, page_data, gateway)
          @survey_id = survey_id
          @page_data = page_data
          @item_mapper = ItemMapper.new(gateway)
        end

        def build_entity
          Entity::Page.new(
            id: nil,
            index: index,
            title: title,
            items: items
          )
        end

        private

        def index
          @page_data['properties']['index']
        end

        def title
          @page_data['properties']['title']
        end

        def items
          @item_mapper.load_several(@survey_id, @page_data['properties']['title'])
        end
      end
    end
  end
end
