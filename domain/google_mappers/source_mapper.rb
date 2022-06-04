# frozen_string_literal: true

module SurveyMoonbear
  # Data Structure for Visual Report Source
  module Google
    # Data Mapper for source
    class SourceMapper
      def initialize(gateway)
        @gateway = gateway
      end

      def load_several(spreadsheet_id, title, redis, key)
        redis_source = redis.get(key)
        sources_data =
          if redis_source['source']
            redis_source['source']
          else
            google_sources_data = @gateway.items_data(spreadsheet_id, title)
            google_sources_data = google_sources_data['values'].reject(&:empty?) # Remove empty rows
            google_sources_data.shift # Remove the first row of spreadsheet (titles for users)
            redis_source['source'] = google_sources_data
            redis.update(key, redis_source)
            google_sources_data
          end

        return nil unless sources_data

        sources_data.map do |source_data|
          SourceMapper.build_entity(source_data)
        end
      end

      def self.build_entity(source_data)
        DataMapper.new(source_data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(source_data)
          @source_data = source_data
        end

        def build_entity
          Entity::Source.new(
            id: nil,
            source_type: source_type,
            source_name: source_name,
            source_id: source_id,
            case_id: case_id,
            sso_email: sso_email
          )
        end

        private

        def source_type
          @source_data[0]
        end

        def source_name
          @source_data[1]
        end

        def source_id
          @source_data[2]
        end

        def case_id
          @source_data[3]
        end

        def sso_email
          @source_data[4]
        end
      end
    end
  end
end
