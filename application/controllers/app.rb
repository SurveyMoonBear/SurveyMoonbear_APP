require 'roda'
require 'econfig'
require 'slim'
require 'slim/include'
require 'google/api_client/client_secrets'

module SurveyMoonbear
  # Web API
  class App < Roda
    plugin :render, engine: 'slim', views: 'presentation/views'
    plugin :assets, css: 'style.css', path: 'presentation/assets'
    plugin :environments
    plugin :json
    plugin :halt

    extend Econfig::Shortcut
    Econfig.env = environment.to_s
    Econfig.root = '.'

    route do |routing|
      app = App
      config = App.config

      # GET / request
      routing.root do
        url = 'https://accounts.google.com/o/oauth2/v2/auth'
        scope = 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive.file'
        params = ["client_id=#{config.GOOGLE_CLIENT_ID}",
                  "redirect_uri=#{config.APP_URL}/account/login/google_callback",
                  'response_type=code',
                  "scope=#{scope}"]
        google_sso_url = "#{url}?#{params.join('&')}"

        view 'home', locals: { google_sso_url: google_sso_url }
      end

      # /account branch
      routing.on 'account' do
        # /account/login branch
        routing.on 'login' do
          # GET /account/login/register_callback request
          routing.get 'google_callback' do
            begin
              account_data = FindAuthenticatedGoogleAccount.new(config)
                                                           .call(routing.params['code'])
              account = Google::AccountMapper.new.load(account_data)
            rescue StandardError
              routing.halt(404, error: 'Account not found')
            end

            stored_account = Repository::For[account.class].find_or_create(account)
            response.status = 201
            stored_account.to_h
            puts 'login successfully!'
            routing.redirect '/'
          end
        end
      end
    end
  end
end
