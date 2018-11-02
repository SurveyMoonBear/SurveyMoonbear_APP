class GoogleAuthHelper
  def self.exchange_access_token(config)
    response = HTTP.post('https://www.googleapis.com/oauth2/v4/token',
                          params: { refresh_token: config.REFRESH_TOKEN,
                                    client_id: config.GOOGLE_CLIENT_ID,
                                    client_secret: config.GOOGLE_CLIENT_SECRET,
                                    grant_type: 'refresh_token' })
                   .parse
    response['access_token']
  end
end