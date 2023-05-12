# frozen_string_literal: true

require 'dry/transaction'
require 'http'
require 'plotly'
require 'json'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetAssignmentsDistribution
      include Dry::Transaction
      include Dry::Monads

      step :get_distribution_data

      private

      def get_distribution_data(input)
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

        student_count = 0
        hw_score = []
        pr_score = []
        st_score = []
        la_score = []
        qz_score = []

        my_hw_score = []
        my_pr_score = []
        my_st_score = []
        my_la_score = []
        my_qz_score = []

        source1.each do |row|
          next unless valid_email?(row[8])
          student_count += 1

          hw_title.each_with_index do |hw, index|
            if hw_score.length < hw_title.length
              if row[hw].nil? || row[hw].empty?
                hw_score.append(0)
                my_hw_score.append(0) if input[:email] == row[8].downcase
              else
                hw_score.append(row[hw].to_f)
                my_hw_score.append(row[hw].to_f) if input[:email] == row[8].downcase
              end
            elsif index < hw_score.length && !row[hw].nil? && !row[hw].empty?
              hw_score[index] += row[hw].to_f
              my_hw_score.append(row[hw].to_f) if input[:email] == row[8].downcase
            end
          end

          pr_title.each_with_index do |pr, index|
            if pr_score.length < pr_title.length
              if row[pr].nil? || row[pr].empty?
                pr_score.append(0)
                my_pr_score.append(0) if input[:email] == row[8].downcase
              else
                pr_score.append(row[pr].to_f)
                my_pr_score.append(row[pr].to_f) if input[:email] == row[8].downcase
              end
            elsif index < pr_score.length && !row[pr].nil? && !row[pr].empty?
              pr_score[index] += row[pr].to_f
              my_pr_score.append(row[pr].to_f) if input[:email] == row[8].downcase
            end
          end

          st_title.each_with_index do |st, index|
            if st_score.length < st_title.length
              if row[st].nil? || row[st].empty?
                st_score.append(0)
                my_st_score.append(0) if input[:email] == row[8].downcase
              else
                st_score.append(row[st].to_f)
                my_st_score.append(row[st].to_f) if input[:email] == row[8].downcase
              end
            elsif index < st_score.length && !row[st].nil? && !row[st].empty?
              st_score[index] += row[st].to_f
              my_st_score.append(row[st].to_f) if input[:email] == row[8].downcase
            end
          end

          la_title.each_with_index do |la, index|
            if la_score.length < la_title.length
              if row[la].nil? || row[la].empty?
                la_score.append(0)
                my_la_score.append(0) if input[:email] == row[8].downcase
              else
                la_score.append(row[la].to_f)
                my_la_score.append(row[la].to_f) if input[:email] == row[8].downcase
              end
            elsif index < la_score.length && !row[la].nil? && !row[la].empty?
              la_score[index] += row[la].to_f
              my_la_score.append(row[la].to_f) if input[:email] == row[8].downcase
            end
          end

          qz_title.each_with_index do |qz, index|
            if qz_score.length < qz_title.length
              if row[qz].nil? || row[qz].empty?
                qz_score.append(0)
                my_qz_score.append(0) if input[:email] == row[8].downcase
              else
                qz_score.append(row[qz].to_f)
                my_qz_score.append(row[qz].to_f) if input[:email] == row[8].downcase
              end
            elsif index < qz_score.length && !row[qz].nil? && !row[qz].empty?
              qz_score[index] += row[qz].to_f
              my_qz_score.append(row[qz].to_f) if input[:email] == row[8].downcase
            end
          end
        end
        hw_score_avg = average_score(hw_score.reject{|x| x == 0 }, student_count)
        st_score_avg = average_score(st_score.reject{|x| x == 0 }, student_count)
        pr_score_avg = average_score(pr_score.reject{|x| x == 0 }, student_count)
        la_score_avg = average_score(la_score.reject{|x| x == 0 }, student_count)
        qz_score_avg = average_score(qz_score.reject{|x| x == 0 }, student_count)

        hw = set_plot(hw_x, hw_score_avg, my_hw_score.reject{|x| x == 0 })
        pr = set_plot(pr_x, pr_score_avg, my_pr_score.reject{|x| x == 0 })
        st = set_plot(st_x, st_score_avg, my_st_score.reject{|x| x == 0 })
        la = set_plot(la_x, la_score_avg, my_la_score.reject{|x| x == 0 })
        qz = set_plot(qz_x, qz_score_avg, my_qz_score.reject{|x| x == 0 })
        data = [hw, pr, st, la, qz]
        Success(data)
      rescue StandardError => e
        Failure('Failed to get assignment distribution.')
      end

      def average_score(total_scores, student_count)
        total_scores.map do |score|
          score = (score.round(2) / student_count).round(2)
        end
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

      def set_plot(title, average_score, my_score)
        # data for the chart
        x = title
        y1 = average_score
        y2 = my_score
        y = [y1, y2]
        [x, y]
      end
    end
  end
end
