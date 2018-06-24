require 'http'

module SurveyMoonbear
  # Returns an authenticated user, or nil
  class FindAuthenticatedGoogleAccount
    def initialize(config)
      @config = config
    end

    def call(code)
      access_token = get_access_token(code)

      account = get_google_account(access_token)
      load_from_db(account)
    end

    def get_access_token(code)
      HTTP.headers(accept: 'application/json')
          .post('https://www.googleapis.com/oauth2/v4/token',
                form: { client_id: @config.GOOGLE_CLIENT_ID,
                        client_secret: @config.GOOGLE_CLIENT_SECRET,
                        grant_type: 'authorization_code',
                        redirect_uri: "#{@config.APP_URL}/account/login/google_callback",
                        code: code })
          .parse['access_token']
    end

    def get_google_account(access_token)
      google_account = HTTP.get("https://www.googleapis.com/oauth2/v1/userinfo?alt=json&access_token=#{access_token}")
                           .parse

      account = { 'email' => google_account['email'],
                  'username' => google_account['name'],
                  'access_token' => access_token }

      Google::AccountMapper.new.load(account)
    end

    def load_from_db(account)
      Repository::For[account.class].find_or_create(account)
    end
  end
end
