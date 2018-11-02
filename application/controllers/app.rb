require 'roda'
require 'econfig'
require 'slim'
require 'slim/include'
require 'google/api_client/client_secrets'
require 'json'
require 'csv'

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
    plugin :all_verbs

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
          # GET /account/login/google_callback request
          routing.get 'google_callback' do
            begin
              logged_in_account = FindAuthenticatedGoogleAccount.new(config)
                                                                .call(routing.params['code'])
            rescue StandardError
              routing.halt(404, error: 'Account not found')
            end

            response.status = 201
            logged_in_account = logged_in_account.to_h
            puts logged_in_account
            if logged_in_account
              SecureSession.new(session).set(:current_account, logged_in_account)
              # flash[:notice] = "Hello #{logged_in_account['username']}!"
              routing.redirect '/survey_list'
            else
              flash[:error] = 'Login fail!'
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

        # GET /survey_list
        routing.get do
          routing.redirect '/' unless @current_account

          surveys = Repository::For[Entity::Survey]
                    .find_owner(@current_account['id'])

          view 'survey_list', locals: { surveys: surveys, config: config }
        end

        routing.post 'create' do
          @new_survey = CreateSurvey.new(@current_account, config)
                                    .call(routing.params['title'])

          if @new_survey
            flash[:notice] = "#{@new_survey.title} is created!"
          else
            flash[:error] = "Fail to create #{@new_survey.title}. :("
          end

          routing.redirect '/survey_list'
        end
      end

      routing.on 'survey', String do |survey_id|
        @current_account = SecureSession.new(session).get(:current_account)

        routing.post 'update_settings' do
          response = EditSurveyTitle.new(@current_account)
                                    .call(survey_id, routing.params)

          routing.redirect '/survey_list'
        end

        # GET /survey/preview with params: survey_id, page
        routing.on 'preview' do
          routing.get do
            response = PreviewSurveyInHTML.new.with_step_args(get_survey_from_spreadsheet: [@current_account])
                                              .call(survey_id)

            if response.failure?
              flash[:error] = response.failure + ' Please try again.'
              routing.redirect '/'
            else
              preview_survey = response.value!
              view 'survey_preview',
                   layout: false,
                   locals: { title: preview_survey[:title], questions: preview_survey[:questions] }
            end
          end
        end

        # GET survey/[survey_id]/start
        routing.get 'start' do
          response = GetSurveyToStart.new.with_step_args(get_survey_from_spreadsheet: [@current_account])
                                         .call(survey_id)

          flash[:error] = response.failure + ' Please try again.' if response.failure?
          routing.redirect '/survey_list'
        end

        # GET survey/[survey_id]/close
        routing.get 'close' do
          response = GetSurveyAndClose.new.call(survey_id)

          flash[:error] = response.failure + ' Please try again.' if response.failure?
          routing.redirect '/survey_list'
        end

        # DELETE survey/[survey_id]
        routing.delete do
          response = DeleteSurvey.new(@current_account, config).call(survey_id)
          response.title

          flash[:notice] = "#{response.title} has been deleted!"

          routing.redirect '/survey_list', 303
        end

        routing.on 'responses_detail' do
          routing.get do
            survey = GetSurveyFromDatabase.new.call(survey_id)

            arr_launches = []
            survey.launches.each do |launch|
              next if launch.responses.length.zero?
              arr_responses = []
              launch.responses.each do |response|
                arr_responses.push(response.respondent_id)
              end
              arr_responses.uniq!
              stime = launch.started_at
              stime.utc.to_s
              start_time = stime.strftime '%Y-%m-%dT%H:%M:%SZ'
              file_name = stime.strftime '%Y%m%d%H%M%S'
              arr_launches.push([start_time, launch.id, file_name, arr_responses.length])
            end

            arr_launches
          end
        end

        routing.on 'download', String, String do |launch_id, file_name|
          routing.get do
            response['Content-Type'] = 'application/csv'

            TransformResponsesToCSV.new.call(survey_id, launch_id)
          end
        end
      end

      routing.on 'onlinesurvey', String, String do |survey_id, launch_id|
        routing.on 'submit' do
          routing.is do
            # GET onlinesurvey/[survey_id]/[launch_id]/submit
            routing.get do
              survey = GetSurveyFromDatabase.new.call(survey_id)
              surveys_started = SecureSession.new(session).get(:surveys_started)

              if surveys_started.nil?
                routing.redirect "/onlinesurvey/#{survey_id}/#{launch_id}"
              end

              view 'survey_finish',
                   layout: false,
                   locals: { survey: survey }
            end

            # POST onlinesurvey/[survey_id]/[launch_id]/submit
            routing.post do
              surveys_started = SecureSession.new(session).get(:surveys_started)
              respondent = surveys_started.find do |survey_started|
                survey_started['survey_id'] == survey_id
              end

              StoreResponses.new(survey_id, launch_id)
                            .call(respondent['respondent_id'], routing.params)

              surveys_started.reject! do |survey_started|
                survey_started['survey_id'] == survey_id
              end

              if surveys_started
                SecureSession.new(session).set(:surveys_started, surveys_started)
              else
                SecureSession.new(session).delete(:surveys_started)
              end

              routing.redirect
            end
          end
        end

        routing.on 'closed' do
          routing.get do
            survey = GetSurveyFromDatabase.new.call(survey_id)

            if survey && survey.state == 'started' && survey.launch_id == launch_id
              routing.redirect "/onlinesurvey/#{survey_id}/#{launch_id}"
            end

            view 'survey_closed',
                 layout: false,
                 locals: { survey: survey }
          end
        end

        # GET /onlinesurvey/[survey_id]/[launch_id]
        routing.get do
          survey = GetSurveyFromDatabase.new.call(survey_id)
          url_params = JSON.generate(routing.params)

          if survey.nil? || survey.launch_id != launch_id || survey.state != 'started'
            routing.redirect "/onlinesurvey/#{survey_id}/#{launch_id}/closed"
          end

          questions = TransfromSurveyItemsToHTML.new.call(survey)

          survey_url = "#{config.APP_URL}/onlinesurvey/#{survey.id}/#{survey.launch_id}"

          surveys_started = SecureSession.new(session).get(:surveys_started)
          if surveys_started
            flag = surveys_started.find do |survey_started|
              survey_started['survey_id'] == survey_id
            end

            if flag.nil?
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
               locals: { survey: survey,
                         survey_url: survey_url,
                         questions: questions,
                         url_params: url_params }
        end
      end
    end
  end
end
