# frozen_string_literal: true

require_relative 'study_mapper'
require_relative '../google_mappers/account_mapper'
require 'time'

module SurveyMoonbear
  module Mapper
    # Data Mapper object for Notification
    class NotificationMapper
      def load(data)
        notification = {}
        notification[:data] = data[:params]
        notification[:survey] = data[:survey]
        notification[:study] = data[:study]
        notification[:owner] = data[:current_account]
        build_entity(notification)
      end

      def build_entity(notification)
        DataMapper.new(notification).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(notification)
          @notification = notification
          @account_mapper = Google::AccountMapper.new
        end

        def build_entity
          SurveyMoonbear::Entity::Notification.new(
            id: nil,
            owner: owner,
            study: study,
            survey: stusurveydy,
            type: type,
            title: title,
            fixed_timestamp: fixed_timestamp,
            content: content,
            notification_tz: notification_tz,
            repeat_at: notification_tz,
            repeat_set_time: repeat_set_time,
            repeat_random_every: repeat_random_every,
            repeat_random_start: repeat_random_start,
            repeat_random_end: repeat_random_end,
            created_at: nil
          )
        end

        def owner
          @account_mapper.load(@notification[:owner])
        end

        def study
          @notification[:study]
        end

        def survey
          @notification[:survey]
        end

        def type
          @notification[:data]['type']
        end

        def title
          @notification[:data]['title']
        end

        def fixed_timestamp
          @notification[:data]['fixed_timestamp']
        end

        def content
          @notification[:data]['content']
        end

        def notification_tz
          @notification[:data]['notification_tz']
        end

        def repeat_at
          @notification[:data]['repeat_at']
        end

        def repeat_set_time
          @notification[:data]['repeat_set_time']
        end

        def repeat_random_every
          @notification[:data]['repeat_random_every']
        end

        def repeat_random_start
          @notification[:data]['repeat_random_start']
        end

        def repeat_random_end
          @notification[:data]['repeat_random_end']
        end
      end
    end
  end
end
