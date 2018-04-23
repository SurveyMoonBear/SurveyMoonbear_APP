require_relative 'account_mapper.rb'

module SurveyMoonbear
  module Google
    # Data Mapper object for Google's spreadsheet
    class SurveyMapper
      def initialize; end

      def load(data)
        build_entity(data)
      end

      def build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          SurveyMoonbear::Entity::Survey.new(
            id: nil,
            owner: owner,
            origin_id: origin_id,
            title: title
          )
        end

        def owner
          AccountMapper.build_entity(@data[:owner])
        end

        def origin_id
          @data[:origin_id]
        end

        def title
          @data[:title]
        end
      end
    end
  end
end
