# frozen_string_literal: true

require 'http'
require 'uri'

module SurveyMoonbear
  module Google
    module Api
      # Gateway class to talk to Calendar API
      class Calendar
        def initialize(access_token)
          @access_token = access_token
        end

        # return calendar's metadata
        # if the calendar doesn't exist, it will return 404 not found
        def check_calendar_exist(calendar_id)
          check_cal_url = gcal_v3_path("/calendars/#{calendar_id}")
          Api.get_with_google_auth(check_cal_url, @access_token).parse
        end

        def subscribe_calendar(calendar_id)
          subscribe_cal_url = gcal_v3_path("/users/me/calendarList?access_token=#{@access_token}")
          data = { 'id': calendar_id }
          Api.post_with_google_auth(subscribe_cal_url, @access_token, data).parse
        end

        # return full details of the events
        def events_details_data(calendar_id, start_date, end_date)
          start_date = URI.encode_www_form_component(start_date.rfc3339)
          end_date = URI.encode_www_form_component(end_date.rfc3339)
          get_events_url = gcal_v3_path("/calendars/#{calendar_id}/events?orderBy=startTime&singleEvents=true&timeMax=#{end_date}&timeMin=#{start_date}")
          Api.get_with_google_auth(get_events_url, @access_token).parse
        end

        def events_data(calendar_id, start_date, end_date)
          events_url = gcal_v3_path('/freeBusy')
          data = {
            "timeMin": start_date.rfc3339,
            "timeMax": end_date.rfc3339,
            # "timeZone": string,
            "items": [{ "id": calendar_id }]
          }
          Api.post_with_google_auth(events_url, @access_token, data).parse
        end

        def parse_calendar_list(calendar_list)
          calendar_list.map { |cal_id| { "id": cal_id } }
        end

        def all_events_data(calendar_list, start_date, end_date)
          events_url = gcal_v3_path('/freeBusy')
          data = {
            "timeMin": start_date.rfc3339,
            "timeMax": end_date.rfc3339,
            # "timeZone": string,
            "items": parse_calendar_list(calendar_list)
          }
          Api.post_with_google_auth(events_url, @access_token, data).parse
        end

        private

        def gcal_v3_path(path)
          "https://www.googleapis.com/calendar/v3#{path}"
        end
      end
    end
  end
end
