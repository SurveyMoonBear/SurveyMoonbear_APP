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

      # input {"option_name"=>{...}, "option_name2"=>{...}, "option_name3"=>{...}
      def build_html(input)
        html_arr = input[:responses_to_chart].keys.map do |name|
          "<canvas id='#{name}_chart' width='400' height='400'></canvas>"
        end

        Success(html_arr)
      rescue StandardError => e
        puts e
        Failure('Failed to build html')
      end
    end
  end
end
