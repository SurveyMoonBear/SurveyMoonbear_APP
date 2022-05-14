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
        def valid_calendar?(calendar_id)
          url = gcal_v3_path("/calendars/#{calendar_id}")
          return true if Api.get_with_google_auth(url, @access_token).parse

          false
        end

        def subscribe_calendar(calendar_id)
          url = gcal_v3_path("/users/me/calendarList?access_token=#{@access_token}")
          data = { 'id': calendar_id }
          Api.post_with_google_auth(url, @access_token, data).parse
        end

        # return full details of the events
        def events_details_data(calendar_id, start_date, end_date)
          start_date = URI.encode_www_form_component(start_date.rfc3339)
          end_date = URI.encode_www_form_component(end_date.rfc3339)
          url = gcal_v3_path("/calendars/#{calendar_id}/events?orderBy=startTime&singleEvents=true&timeMax=#{end_date}&timeMin=#{start_date}")
          Api.get_with_google_auth(url, @access_token).parse
        end

        # return busy event start/end time
        def events_data(calendar_id, start_date, end_date)
          url = gcal_v3_path('/freeBusy')
          data = {
            "timeMin": start_date.rfc3339,
            "timeMax": end_date.rfc3339,
            # "timeZone": string,
            "items": [{ "id": calendar_id }]
          }
          Api.post_with_google_auth(url, @access_token, data).parse['calendars'][calendar_id]['busy']
        end

        def parse_calendar_list(calendar_list)
          calendar_list.map { |cal_id| { "id": cal_id } }
        end

        def all_events_data(calendar_list, start_date, end_date)
          url = gcal_v3_path('/freeBusy')
          data = {
            "timeMin": start_date.rfc3339,
            "timeMax": end_date.rfc3339,
            # "timeZone": string,
            "items": parse_calendar_list(calendar_list)
          }
          Api.post_with_google_auth(url, @access_token, data).parse
        end

        def unsubscribe_calendar(calendar_id)
          calendar_id = URI.encode_www_form_component(calendar_id)
          url = gcal_v3_path("/users/me/calendarList/#{calendar_id}")
          Api.delete_with_google_auth(url, @access_token).status
        end

        def calendar_in_list?(calendar_id)
          url = gcal_v3_path('/users/me/calendarList')
          calendar_list = Api.get_with_google_auth(url, @access_token).parse
          calendar_list['items'].map do |calendar|
            return true if calendar['id'] == calendar_id
          end
          false
        end

        private

        def gcal_v3_path(path)
          "https://www.googleapis.com/calendar/v3#{path}"
        end
      end
    end
  end
end
