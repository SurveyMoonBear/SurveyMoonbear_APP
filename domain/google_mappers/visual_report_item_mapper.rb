module SurveyMoonbear
  # Provide Access to Visual Report Item
  module Google
    # Data Mapper for Spreadsheet values
    class VisualReportItemMapper
      def initialize(gateway)
        @gateway = gateway
      end

      def load_several(spreadsheet_id, redis, key)
        redis_report = redis.get(key)
        pages_data =
          if redis_report['visual_report']
            redis_report['visual_report']
          else
            google_pages_data = @gateway.survey_data(spreadsheet_id)
            google_pages_data['sheets'].shift # remove the first page(source) of spreadsheet
            redis_report['visual_report'] = google_pages_data
            redis.update(key, redis_report)
            google_pages_data
          end
        pages_items = {}
        pages_data['sheets'].map do |page_data|
          title = page_data['properties']['title']
          page_index = page_data['properties']['index']
          items_data = @gateway.items_data(spreadsheet_id, title)
          items_data = items_data['values'].reject(&:empty?) # Remove empty rows
          items_data.shift # Remove the first row of spreadsheet (titles for users)

          return nil unless items_data

          pages_items[title] =
            items_data.each_with_index.map do |item_data|
              VisualReportItemMapper.build_entity(spreadsheet_id, page_index, item_data)
            end
        end
        pages_items
      end

      def self.build_entity(spreadsheet_id, page_index, item_data)
        DataMapper.new(spreadsheet_id, page_index, item_data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(spreadsheet_id, page_index, item_data)
          @spreadsheet_id = spreadsheet_id
          @page_index = page_index
          @item_data = item_data
        end

        def build_entity
          Entity::VisualReportItem.new(
            id: nil,
            spreadsheet_id: @spreadsheet_id,
            page: @page_index,
            graph_title: graph_title,
            data_source: data_source,
            question: question,
            chart_type: chart_type,
            legend: legend,
            self_marker: self_marker,
            score_type: score_type
          )
        end

        private

        def graph_title
          @item_data[0]
        end

        def data_source
          # JSON.parse(@item_data[1])
          @item_data[1]
        end

        def question
          @item_data[2]
        end

        def chart_type
          @item_data[3]
        end

        def legend
          @item_data[4]
        end

        def self_marker
          @item_data[5]
        end

        def score_type
          @item_data[6]
        end
      end
    end
  end
end
