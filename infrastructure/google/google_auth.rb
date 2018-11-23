# frozen_string_literal: true

module SurveyMoonbear
  module Google
    # Gateway class to get access token for Spreadsheet API
    class Auth
      module Errors
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
        account_req_url = Auth.google_auth_v1_path('userinfo?alt=json')

        call_gs_url(account_req_url, access_token).parse
      end

      def get_access_token(code)
        access_req_url = Auth.google_oauth_v4_path('token')
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
        response['access_token']
      end

      def refresh_access_token
        refresh_req_url = Auth.google_oauth_v4_path('token')
        data = { 
          params: {
            refresh_token: @config.REFRESH_TOKEN,
            client_id: @config.GOOGLE_CLIENT_ID,
            client_secret: @config.GOOGLE_CLIENT_SECRET,
            grant_type: 'refresh_token'
          }
        }

        response = post_gs_url(refresh_req_url, data).parse
        response['access_token']
      end

      def self.google_auth_v1_path(path)
        'https://www.googleapis.com/oauth2/v1/' + path
      end

      def self.google_oauth_v4_path(path)
        'https://www.googleapis.com/oauth2/v4/' + path
      end

      private

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
    end
  end
end