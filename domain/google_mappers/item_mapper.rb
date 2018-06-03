module SurveyMoonbear
  # Provide Access to Survey Items
  module Google
    # Data Mapper for Spreadsheet values
    class ItemMapper
      def initialize(gateway)
        @gateway = gateway
      end

      def load_several(survey_id, title)
        items_data = @gateway.items_data(survey_id, title)
        items_data = items_data['values']
        items_data.shift

        return nil unless items_data
        items_data.map do |item_data|
          ItemMapper.build_entity(item_data)
        end
      end

      def self.build_entity(item_data)
        DataMapper.new(item_data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(item_data)
          @item_data = item_data
        end

        def build_entity
          Entity::Item.new(
            id: nil,
            type: type,
            name: name,
            description: description,
            required: required,
            options: options
          )
        end

        private

        def type
          @item_data[0]
        end

        def name
          @item_data[1]
        end

        def description
          @item_data[2]
        end

        def required
          @item_data[3].to_i
        end

        def options
          @item_data[4]
        end
      end
    end
  end
end
