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
        def initialize(access_token)
          @access_token = access_token
        end

        def survey_data(spreadsheet_id)
          survey_req_url = spreadsheet_path(spreadsheet_id)
          Api.get_with_google_auth(survey_req_url, @access_token).parse
        end

        def items_data(spreadsheet_id, title)
          items_req_url = spreadsheet_path([spreadsheet_id, title].join('/values/'))
          Api.get_with_google_auth(items_req_url, @access_token).parse
        end

        def update_gs_title(spreadsheet_id, new_title)
          update_req_url = spreadsheet_path("#{spreadsheet_id}:batchUpdate")
          data = {
            requests: [{
              updateSpreadsheetProperties: {
                properties: { title: new_title },
                fields: 'title'
              }
            }]
          }

          updated_res = Api.post_with_google_auth(update_req_url, @access_token, data).parse
        end

        def set_data_validation(spreadsheet_id, sheet_id, list_datas, row_dict)
          update_req_url = spreadsheet_path("#{spreadsheet_id}:batchUpdate")
          data = {
            requests: [{
              "setDataValidation": {
                "range": {
                  "sheetId": sheet_id,
                  "startRowIndex": row_dict['start'],
                  "endRowIndex": row_dict['end'],
                  "startColumnIndex": 1,
                  "endColumnIndex": 2
                },
                "rule": {
                  "condition": {
                    "type": 'ONE_OF_LIST',
                    "values": list_datas_value(list_datas)
                  },
                  "showCustomUi": true,
                  "strict": false
                }
              }
            }]
          }

          Api.post_with_google_auth(update_req_url, @access_token, data).parse
        end

        # multiple ranges : ranges=A1:D5&ranges=Sheet2!A1:C4 If you not write the sheet name, it will be the first visible sheet
        def get_range_data(spreadsheet_id, ranges)
          req_url = spreadsheet_path("#{spreadsheet_id}/values:batchGet?#{ranges}")
          Api.get_with_google_auth(req_url, @access_token).parse
        end

        private

        def spreadsheet_path(path)
          'https://sheets.googleapis.com/v4/spreadsheets/' + path
        end

        def list_datas_value(list_datas)
          vals = []

          list_datas.each do |list_data|
            vals.append({ "userEnteredValue": list_data })
          end
          vals
        end
      end

      class Drive
        def initialize(access_token)
          @access_token = access_token
        end

        def copy_drive_file(file_id)
          file_copy_url = gdrive_v3_path("#{file_id}/copy?access_token=#{@access_token}")
          
          copied_res = Api.post_with_google_auth(file_copy_url, @access_token).parse
        end

        def create_permission(file_id, role, type)
          permission_req_url = gdrive_v3_path("#{file_id}/permissions")
          res = Api.post_with_google_auth(permission_req_url, 
                                          @access_token,
                                          data={role: role, type: type})
        end

        private

        def gdrive_v3_path(path)
          'https://www.googleapis.com/drive/v3/files/' + path
        end
      end

      private

      def self.get_with_google_auth(url, access_token)
        response = HTTP.auth("Bearer #{access_token}")
                       .get(url)
        
        Response.new(response).response_or_error
      end

      def self.post_with_google_auth(url, access_token, data={})
        response = HTTP.auth("Bearer #{access_token}")
                       .post(url, json: data)

        Response.new(response).response_or_error
      end
    end
  end
end
