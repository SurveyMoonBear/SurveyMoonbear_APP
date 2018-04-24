require 'http'

module SurveyMoonbear
  # Returns a new survey, or nil
  class CreateSurvey
    def initialize(current_account, config)
      @current_account = current_account
      @config = config
    end

    def call(title)
      access_token = get_access_token
      new_spreadsheet = create_spreadsheet(title, access_token)
      add_editor(new_spreadsheet, access_token)
    end

    def get_access_token
      # response = HTTP.post('https://www.googleapis.com/oauth2/v4/token',
      #                      json: { refresh_token: @config.REFRESH_TOKEN,
      #                              client_id: @config.GOOGLE_CLIENT_ID,
      #                              client_secret: @config.GOOGLE_CLIENT_SECRET,
      #                              grant_type: 'refresh_token' })
      #                .parse
      response = HTTP.post("https://www.googleapis.com/oauth2/v4/token?refresh_token=#{@config.REFRESH_TOKEN}&client_id=#{@config.GOOGLE_CLIENT_ID}&client_secret=#{@config.GOOGLE_CLIENT_SECRET}&grant_type=refresh_token").parse
      response['access_token']
    end

    def create_spreadsheet(title, access_token)
      response = HTTP.post("https://www.googleapis.com/drive/v3/files/#{@config.SAMPLE_FILE_ID}/copy?access_token=#{access_token}").parse
      puts response

      { owner: @current_account,
        origin_id: response['id'],
        title: response['name'] }
    end

    def add_editor(new_spreadsheet, access_token)
      response = GoogleSpreadsheet.new(access_token)
                                  .add_editor(new_spreadsheet[:origin_id], @current_account[:email])

      { owner: @current_account,
        origin_id: new_spreadsheet[:origin_id],
        title: new_spreadsheet[:title] }
    end
  end
end
