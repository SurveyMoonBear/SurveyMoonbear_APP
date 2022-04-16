# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformResponsesToHTMLWithChart.new.call(responses_to_chart: "{...}")
    class TransformResponsesToHTMLWithChart
      include Dry::Transaction
      include Dry::Monads

      step :build_html

      private

      # input {entities of VisualReportItem}
      def build_html(input)
        html_arr = input[:charts].each_with_index.map do |chart, idx|
          str = "<div class='form-group mt-5 grid-container'>"
          str += "<p class='lead'>#{chart[1]}</p>"
          str += "<div class='row justify-content-center'><canvas id='chart_#{idx}' width='400' height='400'></canvas></div>"
          str + '</div>'
        # html_arr = input[:responses_to_chart].keys.map do |name|
        #   "<canvas id='#{name}_chart' width='400' height='400'></canvas>"
        end

        Success(html_arr)
      rescue StandardError => e
        puts e
        Failure('Failed to build html')
      end
    end
  end
end
