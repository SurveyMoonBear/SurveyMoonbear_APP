# frozen_string_literal: true

require 'dry/transaction'
require 'http'
require 'plotly'
require 'json'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetAssignmentsReport
      include Dry::Transaction
      include Dry::Monads

      step :get_report_data

      private

      def get_report_data(input)
        source1 = input[:source1]
        assignments = source1[1]
        hw_title = []
        hw_x = []
        st_title = []
        st_x = []
        pr_title = []
        pr_x = []
        la_title = []
        la_x = []
        qz_title = []
        qz_x = []

        # get the correct index
        assignments.each_with_index do |assignment, col|
          next if assignment.length != 4

          if assignment.include?('HW')
            hw_title.append(col)
            hw_x.append(assignment.slice(2,4).to_i)
          elsif assignment.include?('PR')
            pr_title.append(col)
            pr_x.append(assignment.slice(2,4).to_i)
          elsif assignment.include?('ST')
            st_title.append(col)
            st_x.append(assignment.slice(2,4).to_i)
          elsif assignment.include?('LA')
            la_title.append(col)
            la_x.append(assignment.slice(2,4).to_i)
          elsif assignment.include?('QZ')
            qz_title.append(col)
            qz_x.append(assignment.slice(2,4).to_i)
          end
        end

        my_hw_score = []
        my_pr_score = []
        my_st_score = []
        my_la_score = []
        my_qz_score = []

        source1.each do |row|
          next unless valid_email?(row[8]) && input[:email] == row[8].downcase

          hw_title.each do |hw|
            if row[hw].nil? || row[hw].empty?
              my_hw_score.append(0)
            else
              my_hw_score.append(row[hw].to_f)
            end
          end

          pr_title.each do |pr|
            if row[pr].nil? || row[pr].empty?
              my_pr_score.append(0)
            else
              my_pr_score.append(row[pr].to_f)
            end
          end

          st_title.each do |st|
            if row[st].nil? || row[st].empty?
              my_st_score.append(0)
            else
              my_st_score.append(row[st].to_f)
            end
          end

          la_title.each do |la|
            if row[la].nil? || row[la].empty?
              my_la_score.append(0)
            else
              my_la_score.append(row[la].to_f)
            end
          end

          qz_title.each do |qz|
            if row[qz].nil? || row[qz].empty?
              my_qz_score.append(0)
            else
              my_qz_score.append(row[qz].to_f)
            end
          end
        end
        hw = set_plot(hw_x, my_hw_score.reject{|x| x == 0 })
        pr = set_plot(pr_x, my_pr_score.reject{|x| x == 0 })
        st = set_plot(st_x, my_st_score.reject{|x| x == 0 })
        la = set_plot(la_x, my_la_score.reject{|x| x == 0 })
        qz = set_plot(qz_x, my_qz_score.reject{|x| x == 0 })
        data = [hw, pr, st, la, qz]
        Success(data)
      rescue StandardError => e
        Failure('Failed to get assignment report.')
      end

      def valid_email?(email)
        # Regular expression pattern for a valid email address
        pattern = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

        # Test the email against the pattern
        if email =~ pattern
          true
        else
          false
        end
      end

      def set_plot(title, my_score)
        # data for the chart
        x = title
        y = [my_score]
        [x, y]
      end
    end
  end
end
