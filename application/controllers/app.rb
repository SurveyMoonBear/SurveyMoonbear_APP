require 'roda'
require 'econfig'
require 'slim'
require 'slim/include'
require 'google/api_client/client_secrets'
require 'json'

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

    extend Econfig::Shortcut
    Econfig.env = environment.to_s
    Econfig.root = '.'

    route do |routing|
      routing.assets

      app = App
      config = App.config

      SecureDB.setup(config.DB_KEY)

      # GET / request
      routing.root do
        url = 'https://accounts.google.com/o/oauth2/v2/auth'
        scopes = ['https://www.googleapis.com/auth/userinfo.profile',
                  'https://www.googleapis.com/auth/userinfo.email',
                  'https://www.googleapis.com/auth/spreadsheets']
        params = ["client_id=#{config.GOOGLE_CLIENT_ID}",
                  "redirect_uri=#{config.APP_URL}/account/login/google_callback",
                  'response_type=code',
                  "scope=#{scopes.join(' ')}"]
        @google_sso_url = "#{url}?#{params.join('&')}"

        @current_account = SecureSession.new(session).get(:current_account)

        routing.redirect '/survey_list' if @current_account

        view 'home', locals: { google_sso_url: @google_sso_url }
      end

      # /account branch
      routing.on 'account' do
        # /account/login branch
        routing.on 'login' do
          # GET /account/login/register_callback request
          routing.get 'google_callback' do
            begin
              logged_in_account = FindAuthenticatedGoogleAccount.new(config)
                                                                .call(routing.params['code'])

            rescue StandardError
              routing.halt(404, error: 'Account not found')
            end

            response.status = 201
            logged_in_account = logged_in_account.to_h
            if logged_in_account
              SecureSession.new(session).set(:current_account, logged_in_account)
              flash[:notice] = "Hello #{logged_in_account['username']}!"
              routing.redirect '/survey_list'
            else
              puts 'login fail!'
              routing.redirect '/'
            end
          end
        end

        routing.get 'logout' do
          SecureSession.new(session).delete(:current_account)
          routing.redirect '/'
        end
      end

      # /survey_list branch
      routing.on 'survey_list' do
        @current_account = SecureSession.new(session).get(:current_account)
        puts @current_account

        # GET /survey_list
        routing.get do
          routing.redirect '/' unless @current_account

          surveys = Repository::For[Entity::Survey]
                    .find_owner(@current_account['id'])

          view 'survey_list', locals: { surveys: surveys, config: config }
        end

        routing.post 'create' do
          @new_survey = CreateSurvey.new(@current_account, config)
                                    .call(routing.params[:title])

          if @new_survey
            puts 'success!'
          else
            puts 'create fail!'
          end

          routing.redirect '/survey_list'
        end
      end

      routing.on 'survey', String do |survey_id|
        @current_account = SecureSession.new(session).get(:current_account)

        routing.post 'update_settings' do
          response = EditSurveyTitle.new(@current_account)
                                    .call(survey_id, routing.params)
          puts response

          routing.redirect '/survey_list'
        end

        # GET /survey/preview with params: survey_id, page
        routing.on 'preview' do
          routing.get do
            saved_survey = GetSurveyFromDatabase.new.call(survey_id)
            new_survey = GetSurveyFromSpreadsheet.new(@current_account)
                                                 .call(saved_survey.origin_id)
            questions = TransfromSurveyItemsToHTML.new.call(new_survey)

            view 'survey_preview',
                 layout: false,
                 locals: { title: new_survey[:title],
                           questions: questions }
          end
        end

        # GET survey/[survey_id]/export
        routing.get 'start' do
          saved_survey = GetSurveyFromDatabase.new.call(survey_id)
          new_survey = GetSurveyFromSpreadsheet.new(@current_account)
                                               .call(saved_survey.origin_id)
          UpdateSurveyData.new.call(new_survey)

          routing.redirect '/survey_list'
        end

        routing.get 'close' do
          saved_survey = GetSurveyFromDatabase.new.call(survey_id)
          ChangeSurveyState.new.call(saved_survey)

          routing.redirect '/survey_list'
        end
      end

      routing.on 'onlinesurvey', String do |survey_id|
        routing.get do
          survey = GetSurveyFromDatabase.new.call(survey_id)
          questions = TransfromSurveyItemsToHTML.new.call(survey)

          survey_url = "#{config.APP_URL}/onlinesurvey/#{survey[:id]}"

          surveys_started = SecureSession.new(session).get(:surveys_started)
          if surveys_started
            flag = false
            surveys_started.each do |survey_started|
              if survey_started[:survey_id] == survey_id
                flag = true
                break
              end
            end

            unless flag
              respondent_id = SecureRandom.uuid
              surveys_started.push(survey_id: survey_id, respondent_id: respondent_id)
              SecureSession.new(session).set(:surveys_started, surveys_started)
            end
          else
            respondent_id = SecureRandom.uuid
            surveys_started_arr = []
            surveys_started_arr.push(survey_id: survey_id, respondent_id: respondent_id)
            SecureSession.new(session).set(:surveys_started, surveys_started_arr)
          end

          view 'survey_export',
               layout: false,
               locals: { title: survey[:title],
                         survey_id: survey[:id],
                         survey_url: survey_url,
                         questions: questions }
        end

        # POST onlinesurvey/[survey_id]/submit
        routing.post 'submit' do
          surveys_started = SecureSession.new(session).get(:surveys_started)
          respondent = surveys_started.detect do |survey_started|
            survey_started['survey_id'] == survey_id
          end

          responses = {}
          responses[:respondent_id] = respondent['respondent_id']
          responses[:responses] = routing.params
          StoreResponses.new(survey_id).call(responses)

          routing.redirect 'finish'
        end

        # GET survey/[survey_id]/finish
        routing.get 'finish' do
          surveys_started = SecureSession.new(session).get(:surveys_started)
          surveys_started.reject do |survey_started|
            survey_started['survey_id'] == survey_id
          end

          if surveys_started
            SecureSession.new(session).set(:surveys_started, surveys_started)
          end

          view 'survey_finish',
               layout: false,
               locals: { survey_id: survey_id }
        end
      end
    end
  end
end
