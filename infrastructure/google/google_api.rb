# frozen_string_literal: true

require 'http'

module SurveyMoonbear
  module Google
    # Gateway class to talk to Spreadsheet API
    class Api
      module Errors
        # Not allowed to access resource
        Unauthorized = Class.new(StandardError)
        # Requested resource not found
        NotFound = Class.new(StandardError)
      end

      # Encapsulates API response success and errors
      class Response
        HTTP_ERROR = {
          401 => Errors::Unauthorized,
          404 => Errors::NotFound
        }.freeze

        def initialize(response)
          @response = response
        end

        def successful?
          HTTP_ERROR.keys.include?(@response.code) ? false : true
        end

        def response_or_error
          successful? ? @response : raise(HTTP_ERROR[@response.code])
        end
      end

      def initialize(token)
        @gs_token = token
      end

      def survey_data(sp_id)
        survey_req_url = Api.spreadsheet_path(sp_id)
        call_gs_url(survey_req_url).parse
      end

      def items_data(sp_id, title)
        items_req_url = Api.spreadsheet_path([sp_id, title].join('/values/'))
        call_gs_url(items_req_url).parse
      end

      def self.spreadsheet_path(path)
        'https://sheets.googleapis.com/v4/spreadsheets/' + path
      end

      private

      def call_gs_url(url)
        response = HTTP.get(url, params: { access_token: "#{@gs_token}" })

        Response.new(response).response_or_error
      end
    end
  end
end
