# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Return survey title & an array of page HTML strings
    # Usage: Service::TransformResponsesToHTMLWithChart.new.call(pages_charts: "{page_title1=>[[graph1],[...]], page_title2=>[[graph1],[...]]}")
    class TransformResponsesToHTMLWithChart
      include Dry::Transaction
      include Dry::Monads

      step :build_nav_tab
      step :build_nav_item
      step :build_html

      private

      # input {pages_charts:}
      def build_nav_tab(input)
        input[:page_num] = input[:pages_charts].length
        nav_tab = ''
        if input[:page_num] > 1
          nav_tab = "<nav>"
          nav_tab += "<div class='nav nav-tabs' id='nav-tab' role='tablist'>"
        end
        input[:pages_charts].keys.each_with_index do |page_name, i|
          if nav_tab.empty?
            break
          elsif i.zero?
            nav_tab += "<a class='nav-item nav-link active' id='nav-tab-page#{i}' data-toggle='tab' href='#nav-item-page#{i}' role='tab' aria-controls='nav-item-page#{i}' aria-selected='true'>#{page_name}</a>"
          elsif i == (input[:page_num] - 1)
            nav_tab += "<a class='nav-item nav-link' id='nav-tab-page#{i}' data-toggle='tab' href='#nav-item-page#{i}' role='tab' aria-controls='nav-item-page#{i}' aria-selected='false'>#{page_name}</a>"
            nav_tab += '</div></nav>'
          else
            nav_tab += "<a class='nav-item nav-link' id='nav-tab-page#{i}' data-toggle='tab' href='#nav-item-page#{i}' role='tab' aria-controls='nav-item-page#{i}' aria-selected='false'>#{page_name}</a>"
          end
        end
        input[:nav_tab] = nav_tab

        Success(input)
      rescue StandardError
        Failure("Failed to build pages' nav-tab.")
      end

      # input{pages_charts:, page_num:, nav_tab:}
      def build_nav_item(input)
        nav_item = ''
        if input[:nav_tab].empty?
          nav_item = "<div id='chart_div_page0' class='row justify-content-center'></div>"
        else
          nav_item = "<div class='tab-content mb-4' id='nav-tabContent'>"
          input[:pages_charts].keys.each_with_index do |page_name, i|
            if i == 0
              nav_item += "<div class='tab-pane fade show active' id='nav-item-page#{i}' role='tabpanel' aria-labelledby='nav-tab-page#{i}'>"
              nav_item += "<div id='chart_div_page#{i}' class='row justify-content-center'></div></div>"
            else
              nav_item += "<div class='tab-pane fade' id='nav-item-page#{i}' role='tabpanel' aria-labelledby='nav-tab-page#{i}'>"
              nav_item += "<div id='chart_div_page#{i}' class='row justify-content-center'></div></div>"
            end
          end
          nav_item += '</div>'
        end
        input[:nav_item] = nav_item

        Success(input)
      rescue StandardError
        Failure("Failed to build pages' nav-item.")
      end

      # input{pages_charts:, page_num:, nav_tab:, nav_item:}
      def build_html(input)
        str_arr = []
        # if input[:nav_tab].empty?
        #   html_arr =
        #     input[:pages_charts][0].each_with_index.map do |chart, idx|
        #       str = "<div class='form-group mt-5 grid-container'>"
        #       str += "<div class='row justify-content-center' id='chart_#{idx}' style='resize:both; overflow: auto'></div>"
        #       str += '</div>'
        #       leg_str, chart[4] = is_legend_return_html(chart) unless is_legend_return_html(chart).nil?
        #       str += leg_str unless leg_str.nil?
        #       # if chart[6] == 'yes' # legend = yes
        #       #   chart[4].each_with_index do |label, i|
        #       #     label = label.gsub('<br>', '')
        #       #     str += "<div class='container' style='width: 80%'><div class='row'><div class='col-1'>#{alphabet[i]}</div><div class='col-11'><small>#{label}</small></div></div></div>"
        #       #     chart[4][i] = alphabet[i]
        #       #   end
        #       # end
        #       str
        #     end
        # else
        input[:pages_charts].each do |page_name, charts|
          str = ''
          page_name = page_name.gsub(' ', '_')
          charts.each_with_index.map do |chart, idx|
            # html_arr = input[:pages_charts].each_with_index.map do |chart, idx|
            str += "<div class='form-group mt-5 grid-container'>"
            str += "<div class='row' id='chart_#{page_name}_#{idx}' style='resize:both; overflow: auto'></div>"
            str += '</div>'
            legend_arr = is_legend_return_html(chart)
            unless legend_arr.nil?
              str += legend_arr[0]
              chart[4] = legend_arr[1]
            end
          end
          str_arr.append(str)
        end
        input[:pages_chart_val_hash] = str_arr

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to build chart html')
      end

      def is_legend_return_html(chart)
        alphabet = ('a'..'z').to_a
        if chart[6] == 'yes' # legend = yes
          l_str = "<div class='container' style='width: 60%'>"
          chart[4].each_with_index do |label, i|
            label = label.gsub('<br>', '')
            l_str += "<div class='row'><div class='col-12' style='padding-left=25px'><big>#{alphabet[i]}:  </big><small>#{label}</small></div></div>"
            chart[4][i] = alphabet[i]
          end
          l_str += '</div>'

          return [l_str, chart[4]]
        end
        nil
      end
    end
  end
end
