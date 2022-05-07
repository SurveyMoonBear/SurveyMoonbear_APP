# frozen_string_literal: true

module SurveyMoonbear
  module Google
    # Gateway class to get access token for Spreadsheet API
    class Auth
      module Errors
        # Server cannot understand the request
        BadRequest = Class.new(StandardError)
        # Not allowed to access resource
        Unauthorized = Class.new(StandardError)
      end

      # Encapsulates API response success and errors
      class Response
        HTTP_ERROR = {
          400 => Errors::BadRequest,
          401 => Errors::Unauthorized
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

      def initialize(config)
        @config = config
      end

      def get_google_account(access_token)
        account_req_url = google_oauth_v1_path('userinfo?alt=json')

        call_gs_url(account_req_url, access_token).parse
      end

      def get_refresh_and_access_token(code)
        access_req_url = google_oauth_v4_path('token')
        data = {
          form: {
            client_id: @config.GOOGLE_CLIENT_ID,
            client_secret: @config.GOOGLE_CLIENT_SECRET,
            grant_type: 'authorization_code',
            redirect_uri: "#{@config.APP_URL}/account/login/google_callback",
            code: code
          }
        }

        response = post_gs_url(access_req_url, data).parse
        { 'access_token': response['access_token'], 'refresh_token': response['refresh_token'] }
      end

      # get moonbear's access token
      def refresh_access_token
        get_new_access_token(@config.REFRESH_TOKEN)
      end

      # get logged person's acess token
      def refresh_user_access_token(user_refresh_token)
        get_new_access_token(user_refresh_token)
      end

      private

      def google_oauth_v1_path(path)
        'https://www.googleapis.com/oauth2/v1/' + path
      end

      def google_oauth_v4_path(path)
        'https://www.googleapis.com/oauth2/v4/' + path
      end

      def call_gs_url(url, access_token)
        response = HTTP.auth("Bearer #{access_token}")
                       .get(url)

        Response.new(response).response_or_error
      end

      def post_gs_url(url, data)
        response = HTTP.headers(accept: 'application/json')
                       .post(url, data)

        Response.new(response).response_or_error
      end

      def get_new_access_token(role_access_token)
        refresh_req_url = google_oauth_v4_path('token')
        data = {
          params: {
            refresh_token: role_access_token,
            client_id: @config.GOOGLE_CLIENT_ID,
            client_secret: @config.GOOGLE_CLIENT_SECRET,
            grant_type: 'refresh_token'
          }
        }

        response = post_gs_url(refresh_req_url, data).parse
        response['access_token']
      end
    end
  end
end
