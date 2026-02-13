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

    response['items'].map do |item|
      { id: item['id'],
        title: item['title'],
        owner: item['ownerNames'][0] }
    end
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

  def list_permissions(spreadsheet_id)
    # Try without fields parameter first to get all available fields
    url = "#{@drive_url}/#{spreadsheet_id}/permissions?access_token=#{@access_token}"
    response = HTTP.get(url)
    parsed_response = response.parse

    permissions = parsed_response['items'] || parsed_response['permissions'] || []


    permissions
  end

  def remove_editor(spreadsheet_id, user_email)
    all_permissions = list_permissions(spreadsheet_id)

    # Try different field names that Google Drive API v2 might use
    target_permission = all_permissions.find do |p|
      p['emailAddress'] == user_email ||
        p['name'] == user_email ||
        p['value'] == user_email 
    end


    return { status: 'not_found', message: "Permission for #{user_email} not found." } unless target_permission

    permission_id = target_permission['id']
    response = HTTP.delete("#{@drive_url}/#{spreadsheet_id}/permissions/#{permission_id}?access_token=#{@access_token}")

    if response.code == 204
      { status: 'success', removed_permission_id: permission_id }
    else
      { status: 'error', code: response.code, body: response.parse }
    end
  end
end
