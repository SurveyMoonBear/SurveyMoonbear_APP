# frozen_string_literal: true

require_relative '../google_mappers/account_mapper'
require 'time'

module SurveyMoonbear
  module Mapper
    # Data Mapper object for Google's spreadsheet
    class StudyMapper
      def load(data, owner)
        study = {}
        study[:data] = data
        study[:owner] = owner
        build_entity(study)
      end

      def build_entity(study)
        DataMapper.new(study).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(study)
          @study = study
          @account_mapper = Google::AccountMapper.new
        end

        def build_entity
          SurveyMoonbear::Entity::Study.new(
            id: nil,
            owner: owner,
            title: title,
            desc: desc,
            state: nil,
            enable_notification: enable_notification,
            aws_arn: aws_arn,
            track_activity: track_activity,
            activity_start_at: activity_start_at,
            activity_end_at: activity_end_at,
            owned_surveys: owned_surveys,
            created_at: nil
          )
        end

        def owner
          @account_mapper.load(@study[:owner])
        end

        def title
          @study[:data]['title']
        end

        def desc
          @study[:data]['desc']
        end

        def enable_notification
          !@study[:data]['enable_notification'].nil?
        end

        def aws_arn
          '' || @study[:data]['aws_arn']
        end

        def track_activity
          !@study[:data]['track_activity'].nil?
        end

        def activity_start_at
          if @study[:data]['activity_start_at'].empty?
            Time.now
          else
            Time.parse(@study[:data]['activity_start_at'])
          end
        end

        def activity_end_at
          if @study[:data]['activity_end_at'].empty?
            activity_start_at + 86_400 # default end at the next day
          else
            Time.parse(@study[:data]['activity_end_at'])
          end
        end

        def owned_surveys
          [] || @study[:owned_surveys].map! { |survey| @survey_mapper.load(survey) }
        end
      end
    end
  end
end
