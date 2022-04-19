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
        alphabet = ('a'..'z').to_a
        html_arr = input[:charts].each_with_index.map do |chart, idx|
          str = "<div class='form-group mt-5 grid-container'>"
          # str += "<p class='lead'>#{chart[1]}</p>"
          str += "<div class='row justify-content-center' id='chart_#{idx}' style='resize:both; overflow: auto'></div>"
          str += '</div>'
          if chart[6] == 'yes' # legend = yes
            chart[4].each_with_index do |label, i|
              label = label.gsub('<br>', '')
              str += "<div class='container' style='width: 520px'><div class='row'><div class='col-1'>#{alphabet[i]}</div><div class='col-11'><small>#{label}</small></div></div></div>"
              chart[4][i] = alphabet[i]
            end
          end
          str
        end

        Success(html_arr)
      rescue StandardError => e
        puts e
        Failure('Failed to build html')
      end
    end
  end
end
