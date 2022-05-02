# frozen_string_literal: true

require 'roda'
require 'figaro'
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
    plugin :json
    plugin :halt
    plugin :flash
    plugin :hooks
    plugin :all_verbs
    plugin :caching

    route do |routing|
      routing.assets

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

      routing.on 'privacy_policy' do
        routing.get do
          view 'privacy_policy'
        end
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

        # POST /survey_list/copy/[spreadsheet_id]
        routing.post 'copy', String do |spreadsheet_id|
          new_survey = Service::CopySurvey.new.call(config: config,
                                                    current_account: @current_account, 
                                                    spreadsheet_id: spreadsheet_id,
                                                    title: routing.params['title'])

          flash[:error] = "Copy failed: '#{new_survey.failure}' Please try again :(" if new_survey.failure?

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

        # POST /survey/[survey_id]/update_options
        routing.post 'update_options' do
          response = Service::UpdateSurveyOptions.new.call(survey_id: survey_id,
                                                           option: routing.params['option'],
                                                           option_value: routing.params['option_value'])

          if response.failure?
            flash[:error] = response.failure + ' Please try again.'
          end

          routing.redirect '/survey_list'
        end

        # GET /survey/[survey_id]/preview/[spreadsheet_id]
        routing.on 'preview', String do |spreadsheet_id|
          routing.get do
            access_token = Google::Auth.new(config).refresh_access_token
            response = Service::TransformSheetsSurveyToHTML.new.call(survey_id: survey_id,
                                                                     spreadsheet_id: spreadsheet_id,
                                                                     access_token: access_token,
                                                                     current_account: @current_account,
                                                                     random_seed: routing.params['seed'])
            if response.failure?
              flash[:error] = response.failure + ' Please try again.'
              routing.redirect '/survey_list'
            end

            preview_survey = response.value!
            view 'survey_preview',
                  layout: false,
                  locals: { title: preview_survey[:title], pages: preview_survey[:pages] }
          end
        end

        # GET survey/[survey_id]/start
        routing.get 'start' do
          response = Service::StartSurvey.new.call(survey_id: survey_id, current_account: @current_account)
          flash[:error] = "#{response.failure} Please try again." if response.failure?

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
          response = Service::DeleteSurvey.new.call(config: config, survey_id: survey_id)

          flash[:error] = 'Failed to delete the survey. Please try again :(' if response.failure?

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
                launch.responses.each do |res|
                  arr_responses.push(res.respondent_id)
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
            response.success? ? response.value! : response.failure
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

              routing.redirect "/onlinesurvey/#{survey_id}/#{launch_id}" if response.failure? || surveys_started.nil?

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
                                               responses: routing.params,
                                               config: config)

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

            view 'survey_closed', layout: false if response.failure?

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

          html_transform_res = Service::TransformDBSurveyToHTML.new.call(survey_id: survey_id,
                                                                         random_seed: routing.params['seed'])
          if html_transform_res.failure?
            flash[:error] = "#{html_transform_res.failure} Please try again :("
            routing.redirect '/survey_list'
          end

          html_of_pages_arr = html_transform_res.value![:pages]
          routing.params['seed'] = html_transform_res.value![:random_seed] unless html_transform_res.value![:random_seed].nil?

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
                         pages: html_of_pages_arr,
                         url_params: url_params }
        end
      end

      # /analytics branch
      routing.on 'analytics' do
        @current_account = SecureSession.new(session).get(:current_account)

        # GET /analytics
        routing.get do
          routing.redirect '/' unless @current_account
          surveys = Repository::For[Entity::Survey]
                    .find_owner(@current_account['id'])
          visual_reports = Repository::For[Entity::VisualReport]
                           .find_owner(@current_account['id'])

          view 'analytics', locals: { surveys: surveys,
                                      config: config,
                                      visual_reports: visual_reports }
        end

        routing.post 'create' do
          new_visual_report = Service::CreateVisualReport.new.call(config: config,
                                                                   current_account: @current_account,
                                                                   title: routing.params['title'])
          new_visual_report.success? ? flash[:notice] = "#{new_visual_report.value!.title} is created!" :
                                       flash[:error] = 'Failed to create visual report, please try again :('

          routing.redirect '/analytics'
        end

        # # POST /analytics/copy/[spreadsheet_id]
        routing.post 'copy', String do |spreadsheet_id|
          access_token = Google::Auth.new(config).refresh_access_token
          new_visual_report = Service::CopyVisualReport.new.call(access_token: access_token,
                                                                 current_account: @current_account,
                                                                 spreadsheet_id: spreadsheet_id,
                                                                 title: routing.params['title'])

          flash[:error] = "Copy failed: '#{new_visual_report.failure}' Please try again :(" if new_visual_report.failure?

          routing.redirect '/analytics'
        end
      end

      # visual_report/[visual_report_id]
      routing.on 'visual_report', String do |visual_report_id|
        @current_account = SecureSession.new(session).get(:current_account)
        # visual_report/[visual_report_id]/online/[spreadsheet_id]
        routing.on 'online', String do |spreadsheet_id|
          # visual_report/[visual_report_id]/online/[spreadsheet_id]/public
          routing.on 'public' do
            visual_report = Repository::For[Entity::VisualReport]
                            .find_id(visual_report_id)

            access_token = Google::Auth.new(config).refresh_access_token
            responses = Service::TransformVisualSheetsToHTML.new.call(visual_report_id: visual_report_id,
                                                                      spreadsheet_id: spreadsheet_id,
                                                                      access_token: access_token)

            if responses.failure?
              flash[:error] = "#{responses.failure} Please try again :("
              routing.redirect '/analytics'
            end

            response.cache_control public: true, max_age: 3600 if App.environment == :production
            response.cache_control public: true, max_age: 60 if App.environment == :development

            vis_report_object = Views::PublicVisualReport.new(visual_report, responses.value!)

            view 'visual_report', layout: false, locals: { vis_report_object: vis_report_object,
                                                           visual_report: visual_report }
          end

          # visual_report/[visual_report_id]/online/[spreadsheet_id]/design
          routing.on 'design' do
            visual_report = Repository::For[Entity::VisualReport]
                            .find_id(visual_report_id)

            access_token = Google::Auth.new(config).refresh_access_token
            responses = Service::TransformVisualSheetsToHTML.new.call(visual_report_id: visual_report_id,
                                                                      spreadsheet_id: spreadsheet_id,
                                                                      access_token: access_token)

            if responses.failure?
              flash[:error] = "#{responses.failure} Please try again :("
              routing.redirect '/analytics'
            end

            vis_report_object = Views::PublicVisualReport.new(visual_report, responses.value!)

            view 'visual_report', layout: false, locals: { vis_report_object: vis_report_object,
                                                           visual_report: visual_report }
          end

          # customized visual report
          # POST visual_report/[visual_report_id]/online/[spreadsheet_id]
          routing.post do
            student_id = routing.params['respondent']
            student_id = SecureMessage.encrypt(student_id)

            routing.redirect "/visual_report/#{visual_report_id}/online/#{spreadsheet_id}?respondent=#{student_id}"
          end
        end

        # POST visual_report/[visual_report_id]/update_settings
        routing.post 'update_settings' do
          Service::EditVisualReportTitle.new.call(current_account: @current_account,
                                                  visual_report_id: visual_report_id,
                                                  new_title: routing.params['title'])

          routing.redirect '/analytics'
        end

        # DELETE visual_report/[visual_report_id]
        routing.delete do
          response = Service::DeleteVisualReport.new.call(config: config, visual_report_id: visual_report_id)

          flash[:error] = 'Failed to delete the visual report. Please try again :(' if response.failure?

          routing.redirect '/analytics', 303
        end
      end

      # /studies branch
      routing.on 'study_list' do
        @current_account = SecureSession.new(session).get(:current_account)

        # GET /study_list
        routing.get do
          routing.redirect '/' unless @current_account

          studies = Repository::For[Entity::Study]
                    .find_owner(@current_account['id'])

          view 'study_list', locals: { studies: studies, config: config }
        end

        routing.post 'create' do
          # new_study = Service::CreateStudy.new.call(config: config,
          #                                           current_account: @current_account,
          #                                           title: routing.params['title'])

          # new_study.success? ? flash[:notice] = "#{new_study.value!.title} is created!" :
          #                      flash[:error] = "Failed to create study, please try again :("

          routing.redirect '/study_list'
        end

        # POST /study_list/copy/[spreadsheet_id]
        routing.post 'copy' do
          # new_study = Service::CopyStudy.new.call(config: config,
          #                                         current_account: @current_account,
          #                                         title: routing.params['title'])

          # flash[:error] = "Copy failed: '#{new_study.failure}' Please try again :(" if new_study.failure?

          routing.redirect '/study_list'
        end
      end
    end
  end
end
