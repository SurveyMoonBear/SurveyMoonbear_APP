# frozen_string_literal: true

require 'http'

module SurveyMoonbear
  module Google
    module Api
      # Gateway class to talk to Calendar API
      class Calendar
        def initialize(access_token)
          @access_token = access_token
        end

        def check_calendar_exist(calendar_id)
          check_cal_url = gcal_v3_path("/calendars/#{calendar_id}")
          Api.get_with_google_auth(check_cal_url, @access_token).parse
        end

        def subscribe_calendar(calendar_id)
          subscribe_cal_url = gcal_v3_path("/users/me/calendarList?access_token=#{@access_token}")
          data = { 'id': calendar_id }
          Api.post_with_google_auth(subscribe_cal_url, @access_token, data).parse
        end

        private

        def gcal_v3_path(path)
          "https://www.googleapis.com/calendar/v3#{path}"
        end
      end
    end
  end
end
