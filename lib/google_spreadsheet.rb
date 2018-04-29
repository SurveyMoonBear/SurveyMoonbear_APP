require 'http'
require 'json'

# Library for Google Spreadsheet related operation
class GoogleSpreadsheet
  def initialize(access_token)
    @access_token = access_token
    @spreadsheet_url = 'https://sheets.googleapis.com/v4/spreadsheets'
    @drive_url = 'https://www.googleapis.com/drive/v2/files'
  end

  def create
    # response = HTTP.post("#{@spreadsheet_url}?access_token=#{@access_token}",
    #                      { properties: { title: title } }.to_json)
    #                .parse
    response = HTTP.post("#{@spreadsheet_url}?access_token=#{@access_token}")
                   .parse
    response
  end

  def copy_to(origin_spreadsheet_id, sheet_id, destination_spreadsheet_id)
    HTTP.post("#{@spreadsheet_url}/#{origin_spreadsheet_id}/sheets/#{sheet_id}:copyTo",
              json: { destinationSpreadsheetId: destination_spreadsheet_id,
                      access_token: @access_token })
        .parse
  end

  def sheets(spreadsheet_id, range = nil)
    response = HTTP.get("#{@spreadsheet_url}/#{spreadsheet_id}",
                        json: { range: range,
                                access_token: @access_token })
                   .parse
    response.sheets
  end

  def read(spreadsheet_id, range)
    response = HTTP.get("#{@spreadsheet_url}/#{spreadsheet_id}/values/#{range}",
                        json: { access_token: @access_token })
                   .parse
    response.values
  end

  def list_all_spreadsheet
    mime_type = 'application/vnd.google-apps.spreadsheet'
    query_string = "mimeType = '#{mime_type}' and trashed = false"
    response = HTTP.get('https://www.googleapis.com/drive/v2/files',
                        json: { q: query_string,
                                access_token: @access_token })
                   .parse

    response.items.map { |item| { id: item.id, title: item.title } }
  end

  def delete_spreadsheet(spreadsheet_id)
    HTTP.delete("https://www.googleapis.com/drive/v2/files/#{spreadsheet_id}")
  end

  def add_editor(spreadsheet_id, user_email)
    response = HTTP.post("#{@drive_url}/#{spreadsheet_id}/permissions?access_token=#{@access_token}",
                         json: { role: 'writer',
                                 type: 'user',
                                 value: user_email })
                   .parse

    { id: response['id'],
      user_name: response['name'],
      emailAddress: response['emailAddress'] }
  end
end
