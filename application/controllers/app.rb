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
            logged_in_account_res = Service::FindAuthenticatedGoogleAccount.new.call(config: config, 
                                                                                     code: routing.params['code'])
            if logged_in_account_res.failure?
              puts logged_in_account_res.failure

              flash[:error] = 'Login failed. Please try again :('
              routing.redirect '/'
            else
              logged_in_account = logged_in_account_res.value!.to_h

              SecureSession.new(session).set(:current_account, logged_in_account)
              routing.redirect '/survey_list'
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
          new_survey = Service::CreateSurvey.new.call(config: config, 
                                                      current_account: @current_account, 
                                                      title: routing.params['title'])

          new_survey.success? ? flash[:notice] = "#{new_survey.value!.title} is created!" :
                                flash[:error] = "Failed to create survey, please try again :("

          routing.redirect '/survey_list'
        end
      end

      routing.on 'survey', String do |survey_id|
        @current_account = SecureSession.new(session).get(:current_account)

        routing.post 'update_settings' do
          Service::EditSurveyTitle.new.call(current_account: @current_account, 
                                            survey_id: survey_id, 
                                            new_title: routing.params['title'])

          routing.redirect '/survey_list'
        end

        # GET /survey/preview with params: survey_id, page
        routing.on 'preview' do
          routing.get do
            response = Service::TransformSurveyItemsToHTML.new.call(survey_id: survey_id, 
                                                                    current_account: @current_account)
            if response.failure?
              flash[:error] = response.failure + ' Please try again.'
              routing.redirect '/survey_list'
            end

            preview_survey = response.value!
            view 'survey_preview',
                  layout: false,
                  locals: { title: preview_survey[:title], questions: preview_survey[:questions] }
          end
        end

        # GET survey/[survey_id]/start
        routing.get 'start' do
          response = Service::StartSurvey.new.call(survey_id: survey_id, 
                                                   current_account: @current_account)

          flash[:error] = response.failure + ' Please try again.' if response.failure?

          routing.redirect '/survey_list'
        end

        # GET survey/[survey_id]/close
        routing.get 'close' do
          response = Service::CloseSurvey.new.call(survey_id: survey_id)

          flash[:error] = response.failure + ' Please try again.' if response.failure?

          routing.redirect '/survey_list'
        end

        # DELETE survey/[survey_id]
        routing.delete do
          response = Service::DeleteSurvey.new.call(config: config, 
                                                    survey_id: survey_id)

          flash[:error] = "Failed to delete the survey. Please try again :(" if response.failure?
          
          routing.redirect '/survey_list', 303
        end

        routing.on 'responses_detail' do
          routing.get do
            response = Service::GetSurveyFromDatabase.new.call(survey_id: survey_id)

            if response.failure?
              puts response.failure
              arr_launches = []
            else
              survey = response.value!
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
        end

        routing.on 'download', String, String do |launch_id, file_name|
          routing.get do
            response['Content-Type'] = 'application/csv'

            response = Service::TransformResponsesToCSV.new.call(survey_id: survey_id, launch_id: launch_id)
            response.success? ? response.value! : 
                                response.failure
          end
        end
      end

      routing.on 'onlinesurvey', String, String do |survey_id, launch_id|
        @current_account = SecureSession.new(session).get(:current_account)

        routing.on 'submit' do
          routing.is do
            # GET onlinesurvey/[survey_id]/[launch_id]/submit
            routing.get do
              response = Service::GetSurveyFromDatabase.new.call(survey_id: survey_id)
              surveys_started = SecureSession.new(session).get(:surveys_started)

              if response.failure? || surveys_started.nil?
                routing.redirect "/onlinesurvey/#{survey_id}/#{launch_id}"
              end

              view 'survey_finish',
                   layout: false,
                   locals: { survey: response.value! }
            end

            # POST onlinesurvey/[survey_id]/[launch_id]/submit
            routing.post do
              surveys_started = SecureSession.new(session).get(:surveys_started)
              respondent = surveys_started.find do |survey_started|
                survey_started['survey_id'] == survey_id
              end

              Service::StoreResponses.new.call(survey_id: survey_id, 
                                               launch_id: launch_id, 
                                               respondent_id: respondent['respondent_id'], 
                                               responses: routing.params)

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

        # GET /onlinesurvey/[survey_id]/[launch_id]/closed
        routing.on 'closed' do
          routing.get do
            response = Service::GetSurveyFromDatabase.new.call(survey_id: survey_id)
            
            if response.failure?
              view 'survey_closed', layout: false
            end

            survey = response.value!

            # Redirect to the survey export page if the survey isn't nil && hasn't been closed
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
          get_db_survey_res = Service::GetSurveyFromDatabase.new.call(survey_id: survey_id)
          if get_db_survey_res.failure?
            flash[:error] = "#{get_db_survey_res.failure}. Please try again :("
            routing.redirect '/survey_list'
          end

          survey = get_db_survey_res.value!

          # Redirect to the survey closed page if the survey is nil || not started
          if survey.nil? || survey.launch_id != launch_id || survey.state != 'started'
            routing.redirect "/onlinesurvey/#{survey_id}/#{launch_id}/closed"
          end

          html_transform_res = Service::TransformSurveyItemsToHTML.new.call(survey_id: survey_id, 
                                                                            current_account: @current_account)
          if html_transform_res.failure?
            flash[:error] = "#{html_transform_res.failure}. Please try again :("
            routing.redirect '/survey_list'
          end

          questions_arr = html_transform_res.value![:questions]

          survey_url = "#{config.APP_URL}/onlinesurvey/#{survey.id}/#{survey.launch_id}"
          url_params = JSON.generate(routing.params)

          # Session setting
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
                         questions: questions_arr,
                         url_params: url_params }
        end
      end
    end
  end
end
