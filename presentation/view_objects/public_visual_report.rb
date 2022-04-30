# frozen_string_literal: true

# module SurveyMoonbear
module Views
  # View for a visual report html
  class PublicVisualReport
    def initialize(visual_report, html)
      @visual_report = visual_report
      @html = html
    end

    def title
      @visual_report.title
    end

    def graphs
      @html[:all_graphs].to_json
    end

    def html_arr
      @html[:pages_chart_val_hash]
    end

    def nav_tab
      @html[:nav_tab]
    end

    def nav_item
      @html[:nav_item]
    end

    def show_enter_id
      false
    end
  end
end
# end
