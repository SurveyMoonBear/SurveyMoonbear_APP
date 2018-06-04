module SurveyMoonbear
  module Google
    # Data Mapper object for Google's accounts
    class ResponseMapper
      def initialize; end

      def load(data)
        ResponseMapper.build_entity(data)
      end

      def self.build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          SurveyMoonbear::Entity::Response.new(
            id: nil,
            respondent_id: respondent_id,
            page_id: page_id,
            item_id: item_id,
            response: response,
            item_type: item_type,
            item_name: item_name,
            item_description: item_description,
            item_required: item_required,
            item_options: item_options
          )
        end

        def respondent_id
          @data['respondent_id']
        end

        def page_id
          @data['page_id']
        end

        def item_id
          @data['item_id']
        end

        def response
          @data['response']
        end

        def item_type
          @data['item_type']
        end

        def item_name
          @data['item_name']
        end

        def item_description
          @data['item_description']
        end

        def item_required
          @data['item_required']
        end

        def item_options
          @data['item_options']
        end
      end
    end
  end
end
