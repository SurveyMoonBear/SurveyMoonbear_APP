# frozen_string_literal: true

module SurveyMoonbear
  module Google
    # Gateway class to get access token for Spreadsheet API
    class Auth
      def initialize(config)
        @config = config
      end

      def refresh_access_token
        response = HTTP.post('https://www.googleapis.com/oauth2/v4/token',
                              params: { refresh_token: @config.REFRESH_TOKEN,
                                        client_id: @config.GOOGLE_CLIENT_ID,
                                        client_secret: @config.GOOGLE_CLIENT_SECRET,
                                        grant_type: 'refresh_token' })
                        .parse
        response['access_token']
      end
    end
  end
end