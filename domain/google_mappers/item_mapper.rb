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
        items_data = items_data['values'].reject(&:empty?) # Remove empty rows
        items_data.shift # Remove the first row of spreadsheet (titles for users)

        return nil unless items_data

        items_data.each_with_index.map do |item_data, index|
          ItemMapper.build_entity(item_data, index + 1)
        end
      end

      def self.build_entity(item_data, order)
        DataMapper.new(item_data, order).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(item_data, order)
          @item_data = item_data
          @order = order
        end

        def build_entity
          Entity::Item.new(
            id: nil,
            order: @order,
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
