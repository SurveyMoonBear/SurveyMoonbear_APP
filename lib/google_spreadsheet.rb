require 'http'
require 'json'

# Library for Google Spreadsheet related operation
class GoogleSpreadsheet
  def initialize(access_token)
    @access_token = access_token
    @spreadsheet_url = 'https://sheets.googleapis.com/v4/spreadsheets'
    @drive_url = 'https://www.googleapis.com/drive/v2/files'
  end

  def create_empty_spreadsheet(gs_title)
    response = HTTP.post("#{@spreadsheet_url}?access_token=#{@access_token}",
                          json: { properties: { title: gs_title } })
                   .parse

    { spreadsheet_id: response['spreadsheetId'], 
      title: response['properties']['title'], 
      sheets: response['sheets'] }
  end

  # Add a single sample sheet page copy to destination spreadsheet (the default first sheet's sheet_id=0)
  def copy_sheet_to(origin_spreadsheet_id, sheet_id, destination_spreadsheet_id)
    response = HTTP.post("#{@spreadsheet_url}/#{origin_spreadsheet_id}/sheets/#{sheet_id}:copyTo&access_token=#{@access_token}",
                          json: { destinationSpreadsheetId: destination_spreadsheet_id })
                   .parse

    { created_sheet_id: response['sheetId'], 
      sheet_title: response['title'], 
      sheet_index: response['index'] }
  end

  def get_sheets(spreadsheet_id)
    response = HTTP.get("#{@spreadsheet_url}/#{spreadsheet_id}&access_token=#{@access_token}")
                   .parse

    { spreadsheet_id: response['spreadsheetId'], 
      title: response['properties']['title'], 
      sheets: response['sheets'] }
  end

  # "range": EX. "A1:B2"(the first sheet), "sheet1!A1:B2", "'sheet title'!A1:B2"
  def get_sheet_values(spreadsheet_id, range)
    response = HTTP.get("#{@spreadsheet_url}/#{spreadsheet_id}/values/#{range}&access_token=#{@access_token}")
                   .parse
    response['values']
  end

  def list_all_spreadsheets
    mime_type = 'application/vnd.google-apps.spreadsheet'
    query_string = "mimeType=%22#{mime_type}%22&trashed=false"
    response = HTTP.get("#{@drive_url}?q=#{query_string}&access_token=#{@access_token}")
                   .parse

    response['items'].map { |item| { id: item['id'], 
                                     title: item['title'], 
                                     owner: item['ownerNames'][0] } }
  end

  def delete_spreadsheet(spreadsheet_id)
    HTTP.auth("Bearer #{@access_token}")
        .delete("https://www.googleapis.com/drive/v2/files/#{spreadsheet_id}")
  end

  def add_editor(spreadsheet_id, user_email)
    response = HTTP.post("#{@drive_url}/#{spreadsheet_id}/permissions?sendNotificationEmails=false&access_token=#{@access_token}",
                         json: { role: 'writer',
                                 type: 'user',
                                 value: user_email })
                   .parse

    { id: response['id'],
      user_name: response['name'],
      emailAddress: response['emailAddress'] }
  end
end
