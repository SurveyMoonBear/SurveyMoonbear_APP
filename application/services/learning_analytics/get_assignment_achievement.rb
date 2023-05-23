# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return text score for customized report

    class GetAssignmentAchievementData
      include Dry::Transaction
      include Dry::Monads

      step :get_achievement

      private

      # TODO: get number of "5" assignment
      def get_achievement(input)
        categorize_score_type = input[:categorize_score_type]

        score_type = ['achievement']
        data = categorize_score_type.select{|key, value| score_type.include? key }

        star = 0
        achievement_result = {}
        data["achievement"].each do |i|
          star = i["score"].to_i
          key = i["title"]
          achievement_result[key] = Array.new(star, 1) + Array.new(3 - star, 0)
        end
        Success(achievement_result)
      rescue StandardError => e
        puts "log[error]:achievement: #{e.full_message}"
        puts "log[error]:star: #{star}"
        Failure('Failed to get achievement data.')
      end
    end
  end
end
