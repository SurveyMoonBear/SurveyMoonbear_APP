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
            item_data: item_data
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

        def item_data
          @data['item_data']
        end
      end
    end
  end
end
