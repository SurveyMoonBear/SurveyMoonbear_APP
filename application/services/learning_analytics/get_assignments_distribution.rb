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
        categorize_score_type = input[:categorize_score_type]

        score_type = ['score_st', 'score_pr', 'score_hw', 'score_qz', 'score_la']
        data = categorize_score_type.select{|key, value| score_type.include? key }

        hw_scores = get_scores(data["score_hw"])
        pr_scores = get_scores(data["score_pr"])
        st_scores = get_scores(data["score_st"])
        qz_scores = get_scores(data["score_qz"])
        la_scores = get_scores(data["score_la"])


        hw = set_plot(hw_scores[0], hw_scores[1], hw_scores[2])
        pr = set_plot(pr_scores[0], pr_scores[1], pr_scores[2])
        st = set_plot(st_scores[0], st_scores[1], st_scores[2])
        la = set_plot(qz_scores[0], qz_scores[1], qz_scores[2])
        qz = set_plot(la_scores[0], la_scores[1], la_scores[2])
        title = ['Homework', 'Peer Review', 'Swirl and Tutorial', 'LA', 'Quiz']
        data = [title, [hw, pr, st, la, qz]].to_json
        Success(data)
      rescue StandardError => e
        Failure('Failed to get assignment distribution.')
      end

      def get_scores(score_data)
        titles = []
        my_all_score = []
        all_score_avg = []
        score_data.each do |item|
          titles.append(item["title"])
          my_score = item["score"].nil? || item["score"].empty? ? 0 : item["score"].to_f
          my_all_score.append(my_score)
          all_scores = item["all_scores"]
          total = 0
          count = 0
          all_scores.each do |class_score|
            score = class_score[1].nil? || class_score[1].empty? ? 0 : class_score[1].to_f
            total += score
            count += 1
          end
          average = (total / count).round(2)
          all_score_avg.append(average)
        end

        [titles, my_all_score, all_score_avg]
      end

      def set_plot(title, my_score, average_score)
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
