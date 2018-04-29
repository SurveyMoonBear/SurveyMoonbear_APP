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
      new_survey_data = create_spreadsheet(title, access_token)
      new_survey = add_editor(new_survey_data, access_token)
      store_into_database(new_survey)
    end

    def get_access_token
      google_oauth_url = 'https://www.googleapis.com/oauth2/v4/token'
      # response = HTTP.post('https://www.googleapis.com/oauth2/v4/token',
      #                      json: { grant_type: 'refresh_token',
      #                              refresh_token: @config.REFRESH_TOKEN,
      #                              client_id: @config.GOOGLE_CLIENT_ID,
      #                              client_secret: @config.GOOGLE_CLIENT_SECRET })
      #                .parse
      response = HTTP.post("#{google_oauth_url}?refresh_token=#{@config.REFRESH_TOKEN}&client_id=#{@config.GOOGLE_CLIENT_ID}&client_secret=#{@config.GOOGLE_CLIENT_SECRET}&grant_type=refresh_token").parse

      response['access_token']
    end

    def create_spreadsheet(title, access_token)
      files_copy_url = "https://www.googleapis.com/drive/v3/files/#{@config.SAMPLE_FILE_ID}/copy"
      response = HTTP.post("#{files_copy_url}?access_token=#{access_token}").parse

      { owner: @current_account,
        origin_id: response['id'],
        title: response['name'] }
    end

    def add_editor(new_survey_data, access_token)
      GoogleSpreadsheet.new(access_token)
                       .add_editor(new_survey_data[:origin_id], @current_account[:email])

      new_survey = { owner: @current_account,
                     origin_id: new_survey_data[:origin_id],
                     title: new_survey_data[:title] }

      Google::SurveyMapper.new.load(new_survey)
    end

    def store_into_database(new_survey)
      Repository::For[new_survey.class].find_or_create(new_survey)
    end
  end
end
