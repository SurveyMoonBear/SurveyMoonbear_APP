module SurveyMoonbear
  # Return a deleted survey
  class DeleteSurvey
    def initialize(current_account, config)
      @current_account = current_account
      @config = config
    end

    def call(survey)
      survey = delete_record_in_database(survey)
      access_token = get_access_token
      delete_spreadsheet(access_token, survey.origin_id)
      survey
    end

    def delete_record_in_database(survey)
      Repository::For[Entity::Survey].delete_from(survey)
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

    def delete_spreadsheet(access_token, spreadsheet_id)
      GoogleSpreadsheet.new(access_token)
                       .delete_spreadsheet(spreadsheet_id)
    end
  end
end
