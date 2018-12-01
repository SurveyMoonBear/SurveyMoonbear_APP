# frozen_string_literal: true

require 'http'

module SurveyMoonbear
  module Google
    module Api
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
      
      # Gateway class to talk to Spreadsheet API
      class Sheets
        def initialize(gs_token)
          @gs_token = gs_token
        end

        def survey_data(spreadsheet_id)
          survey_req_url = spreadsheet_path(spreadsheet_id)
          Api.call_gs_url(survey_req_url, @gs_token).parse
        end
  
        def items_data(spreadsheet_id, title)
          items_req_url = spreadsheet_path([spreadsheet_id, title].join('/values/'))
          Api.call_gs_url(items_req_url, @gs_token).parse
        end
  
        def update_gs_title(spreadsheet_id, new_title)
          update_req_url = spreadsheet_path("#{spreadsheet_id}:batchUpdate")
          data = {
            json: {
              requests: [{
                updateSpreadsheetProperties: {
                  properties: { title: new_title },
                  fields: 'title'
                }
              }]
            }
          }
          
          updated_res = Api.post_google_url(update_req_url, data, @gs_token).parse
        end

        private
  
        def spreadsheet_path(path)
          'https://sheets.googleapis.com/v4/spreadsheets/' + path
        end
      end

      class Drive
        def initialize(token)
          @gs_token = token
        end

        def copy_drive_file(file_id)
          file_copy_url = gdrive_v3_path("#{file_id}/copy?access_token=#{@gs_token}")
          
          copied_res = Api.post_google_url(file_copy_url, @gs_token).parse
        end

        private

        def gdrive_v3_path(path)
          'https://www.googleapis.com/drive/v3/files/' + path
        end
      end

      private

      def self.call_gs_url(url, gs_token)
        response = HTTP.get(url, params: { access_token: "#{gs_token}" })

        Response.new(response).response_or_error
      end

      def self.post_google_url(url, data={}, gs_token)
        response = HTTP.auth("Bearer #{gs_token}")
                       .post(url, data)

        Response.new(response).response_or_error
      end
    end
  end
end
