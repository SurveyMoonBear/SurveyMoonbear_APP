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
    plugin :flash
    plugin :hooks

    ONE_MONTH = 2_592_000

    use Rack::Session::Cookie, expire_after: ONE_MONTH

    extend Econfig::Shortcut
    Econfig.env = environment.to_s
    Econfig.root = '.'

    before do
      @current_account = session[:current_account]
    end

    route do |routing|
      app = App
      config = App.config

      SecureDB.setup(config.DB_KEY)

      # GET / request
      routing.root do
        url = 'https://accounts.google.com/o/oauth2/v2/auth'
        scopes = ['https://www.googleapis.com/auth/userinfo.profile',
                  'https://www.googleapis.com/auth/userinfo.email',
                  'https://www.googleapis.com/auth/spreadsheets',
                  'https://www.googleapis.com/auth/drive.file']
        params = ["client_id=#{config.GOOGLE_CLIENT_ID}",
                  "redirect_uri=#{config.APP_URL}/account/login/google_callback",
                  'response_type=code',
                  "scope=#{scopes.join(' ')}"]
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
              @current_account = FindAuthenticatedGoogleAccount.new(config)
                                                               .call(routing.params['code'])

            rescue StandardError
              routing.halt(404, error: 'Account not found')
            end

            response.status = 201
            @current_account = @current_account.to_h
            if @current_account
              session[:current_account] = @current_account
              flash[:notice] = "Hello #{@current_account['username']}!"
              routing.redirect '/survey_list'
            else
              puts 'login fail!'
              routing.redirect '/'
            end
          end
        end

        routing.get 'logout' do
          session[:current_account] = nil
          routing.redirect '/'
        end
      end

      # /survey_list branch
      routing.on 'survey_list' do
        # GET /survey_list
        routing.get do
          surveys = Repository::For[Entity::Survey]
                    .find_owner(session[:current_account][:id])

          # put 'Create a new survey.' if surveys.none?

          view 'survey_list', locals: { surveys: surveys }
        end

        routing.post 'create' do
          @new_survey = CreateSurvey.new(session[:current_account], config)
                                    .call(routing.params[:title])

          if @new_survey
            puts 'create success!'
          else
            puts 'create fail!'
          end

          routing.redirect '/survey_list'
        end
      end
    end
  end
end
