# frozen_string_literal: true

require 'roda'
require 'figaro'
require 'slim'
require 'slim/include'
require 'google/api_client/client_secrets'
require 'json'
require 'csv'

module SurveyMoonbear
  # rubocop: disable Metrics/ClassLength
  # rubocop: disable Metrics/BlockLength
  # Web API
  class App < Roda
    plugin :render, engine: 'slim', views: 'presentation/views'
    plugin :assets, css: 'style.css', path: 'presentation/assets'
    plugin :public, root: 'presentation/public'
    plugin :json
    plugin :halt
    plugin :flash
    plugin :hooks
    plugin :all_verbs
    plugin :caching

    route do |routing|
      routing.public
      routing.assets

      config = App.config

      SecureDB.setup(config.DB_KEY)

      # GET / request
      routing.root do
        url = 'https://accounts.google.com/o/oauth2/v2/auth'
        # TODO: request additional calendar scopes when user needs
        scopes = ['https://www.googleapis.com/auth/userinfo.profile',
                  'https://www.googleapis.com/auth/userinfo.email',
                  'https://www.googleapis.com/auth/spreadsheets',
                  'https://www.googleapis.com/auth/calendar']
        params = ["client_id=#{config.GOOGLE_CLIENT_ID}",
                  "redirect_uri=#{config.APP_URL}/account/login/google_callback",
                  'response_type=code',
                  'access_type=offline',
                  'prompt=consent',
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
                                                                                     code: routing.params['code'],
                                                                                     login_type: 'admin')
            if logged_in_account_res.failure?
              puts logged_in_account_res.failure

              flash[:error] = 'Login failed. Please try again :('
              routing.redirect '/'
            else
              logged_in_account = logged_in_account_res.value!.to_h

              SecureSession.new(session).set(:current_account, logged_in_account)
              redis = RedisCache.new(config)
              if redis.get('system_access_token').equal? nil
                redis.set('system_access_token', logged_in_account[:access_token], 3000)
              end
              if redis.get('system_refresh_token').equal? nil
                redis.set('system_refresh_token', logged_in_account[:refresh_token])
              end
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
                                                      title: routing.params['title'],
                                                      study_id: routing.params['study_id'])
          redirect_rout = routing.params['rerout']

          if new_survey.success?
            flash[:notice] = "#{new_survey.value!.title} is created!"
          else
            flash[:error] = 'Failed to create survey, please try again :('
          end

          routing.redirect redirect_rout
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

          flash[:error] = "#{response.failure} Please try again." if response.failure?

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
              flash[:error] = "#{response.failure} Please try again."
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

          flash[:error] = "#{response.failure} Please try again." if response.failure?

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

        routing.on 'download', String, String do |launch_id|
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
          unless html_transform_res.value![:random_seed].nil?
            routing.params['seed'] = html_transform_res.value![:random_seed]
          end

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
          is_owner = []
          visual_reports.each do |visual_report|
            is_owner.append(@current_account['email'] == visual_report.owner.email)
          end

          view 'analytics', locals: { surveys: surveys,
                                      config: config,
                                      visual_reports: visual_reports,
                                      is_owner: is_owner }
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

      # report/google_callback
      routing.on 'report' do
        routing.on 'google_callback' do
          code = routing.params['code']
          redirect_route = routing.params['state']

          logged_in_account_res = Service::FindAuthenticatedGoogleAccount.new.call(config: config,
                                                                                   code: code,
                                                                                   login_type: 'report')
            if logged_in_account_res.failure?
              puts logged_in_account_res.failure

              flash[:error] = 'Login failed. Please try again :('
              routing.redirect '/'
            else
              logged_in_account = logged_in_account_res.value!.to_h

              SecureSession.new(session).set(:report_account, logged_in_account)
             
              routing.redirect "#{redirect_route}?code=#{code}"
            end
        end
      end

      # visual_report/[visual_report_id]
      routing.on 'visual_report', String do |visual_report_id|
        @current_account = SecureSession.new(session).get(:current_account)
        @report_account = SecureSession.new(session).get(:report_account)
        # visual_report/[visual_report_id]/online/[spreadsheet_id]
        routing.on 'online', String do |spreadsheet_id|
          # visual_report/[visual_report_id]/online/[spreadsheet_id]/public
          routing.on 'public' do
            response.cache_control public: true, max_age: 3600 if App.environment == :production
            response.cache_control public: true, max_age: 60 if App.environment == :development

            visual_report = Repository::For[Entity::VisualReport]
                            .find_id(visual_report_id)

            access_token = Google::Auth.new(config).refresh_access_token
            responses = Service::GetPublicVisualReport.new.call(visual_report: visual_report,
                                                                spreadsheet_id: spreadsheet_id,
                                                                config: config,
                                                                access_token: access_token)

            if responses.failure?
              flash[:error] = "#{responses.failure} Please try again :("
              routing.redirect '/analytics'
            end

            vis_report_object = Views::PublicVisualReport.new(visual_report, responses.value!)
            view 'visual_report', layout: false, locals: { vis_report_object: vis_report_object,
                                                           visual_report: visual_report }
          end

          # visual_report/[visual_report_id]/online/[spreadsheet_id]/dashboard
          routing.on 'dashboard' do
            routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/dashboard" unless @report_account

            routing.is 'logout' do
              SecureSession.new(session).delete(:report_account)
              @report_account = nil
              routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/dashboard"
            end

            routing.get String do |dashboard_type|
              redis = RedisCache.new(config)
              categorize_score_type = redis.get('categorize_score_type')
              result = Service::GetDashboardData.new.call(redis:redis,
                                                          visual_report_id: visual_report_id,
                                                          dashboard_type: dashboard_type,
                                                          email: @report_account['email'],
                                                          categorize_score_type: categorize_score_type)
              @dashboard_result = result.value!
              view dashboard_type, layout: false, locals: { visual_report_id: visual_report_id,
                                                            spreadsheet_id: spreadsheet_id,
                                                            dashboard_result: @dashboard_result}
            end

            routing.get do
              code = routing.params['code']
              visual_report = Repository::For[Entity::VisualReport]
                              .find_id(visual_report_id)

              redis = RedisCache.new(config)
              puts "log[trace]: system_access_token = #{redis.get('system_access_token')}"
              if redis.get('system_access_token').equal? nil
                new_access_token = Google::Auth.new(config).refresh_access_token
                redis.set('system_access_token', new_access_token, 3000)
              end
              access_token = redis.get('system_access_token')
              sequence_result = Service::GetStudentSequence.new.call(redis: redis,
                                                                     visual_report_id: visual_report_id,
                                                                     email: @report_account['email'])

              if sequence_result.failure == 'Can not find your email'
                flash[:error] = sequence_result.failure
                routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/dashboard"
              end

              result = Service::GetDashboardGroup.new.call(student_sequence: sequence_result.value!)

              responses = Service::GetCustomizedVisualReport.new.call(spreadsheet_id: spreadsheet_id,
                                                                      visual_report_id: visual_report_id,
                                                                      visual_report: visual_report,
                                                                      config: config,
                                                                      code: code,
                                                                      access_token: access_token,
                                                                      email: @report_account['email'])
              text_responses = Service::GetTextReport.new.call(spreadsheet_id: spreadsheet_id,
                                                               visual_report_id: visual_report_id,
                                                               visual_report: visual_report,
                                                               config: config,
                                                               code: code,
                                                               access_token: access_token,
                                                               email: @report_account['email'])
              if result.failure? || responses.failure? || text_responses.failure?
                routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/dashboard"
              end
              vis_report_object = Views::PublicVisualReport.new(visual_report, responses.value!)
              analytics_order = result.value!
              text_responses_result = text_responses.value!.to_json
              text_responses_parse = JSON.parse(text_responses_result)
              text_report_object = text_responses_parse['scores']

              score_type = ['score_st', 'score_pr', 'score_hw', 'score_qz', 'score_la']
              categorize_score_type = text_report_object.group_by { |i| i['score_type'] }
              redis.delete('categorize_score_type') if redis.get('categorize_score_type')
              redis.set('categorize_score_type', categorize_score_type)
              scores = categorize_score_type.reject{|key, value| !score_type.include? key }
              ta = categorize_score_type.select{|key, value| key == 'ta' }['ta'].first
              title = {}

              scores.each_key do |key|
                title[key] = case key
                             when 'score_st'
                              'Tutorial + Quiz (Total 2)'
                             when 'score_pr'
                              'Peer Review (Total 2)'
                             when 'score_hw'
                              'Homework (Total 5)'
                             when 'score_qz'
                              'Quiz (Total 2)'
                            when 'score_la'
                              'LA'
                             else
                              'Others'
                             end
              end

              view 'learning_analytics', layout: false, locals: { visual_report_id: visual_report_id,
                                                                  spreadsheet_id: spreadsheet_id,
                                                                  vis_report_object: vis_report_object,
                                                                  text_report_object: text_report_object,
                                                                  title: title,
                                                                  scores: scores,
                                                                  ta: ta,
                                                                  analytics_order: analytics_order}
            end
          end

          # visual_report/[visual_report_id]/online/[spreadsheet_id]/identify/[report_type]
          routing.on 'identify', String do |report_type|
            # write in service object?
            url = 'https://accounts.google.com/o/oauth2/v2/auth'
            scopes = ['https://www.googleapis.com/auth/userinfo.profile',
                      'https://www.googleapis.com/auth/userinfo.email']
            params = ["client_id=#{config.GOOGLE_CLIENT_ID}",
                      "redirect_uri=#{config.APP_URL}/report/google_callback",
                      'response_type=code',
                      "scope=#{scopes.join(' ')}",
                      "state=/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/#{report_type}"]
            @google_sso_url = "#{url}?#{params.join('&')}"

            visual_report = Repository::For[Entity::VisualReport]
                            .find_id(visual_report_id)
            view 'visual_report_identify', layout: false, locals: { google_sso_url: @google_sso_url, visual_report: visual_report }
          end

          # customized visual report
          routing.on 'score' do
            routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/score" unless @report_account

            routing.is 'logout' do
              SecureSession.new(session).delete(:report_account)
              @report_account = nil
              routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/score"
            end

            # customized visual report
            # GET visual_report/[visual_report_id]/online/[spreadsheet_id]/score
            routing.get do
              code = routing.params['code']

              visual_report = Repository::For[Entity::VisualReport]
                              .find_id(visual_report_id)
              # access_token = Google::Auth.new(config).refresh_access_token
              redis = RedisCache.new(config)
              if redis.get('system_access_token').equal? nil
                new_access_token = Google::Auth.new(config).refresh_access_token
                puts "log[trace]: new_access_token = #{new_access_token}"
                redis.set('system_access_token', new_access_token, 3000)
              end
              access_token = redis.get('system_access_token')

              sequence_result = Service::GetStudentSequence.new.call(redis: redis,
                                                            visual_report_id: visual_report_id,
                                                            email: @report_account['email'])

              if sequence_result.failure == 'Can not find your email'
                flash[:error] = sequence_result.failure
                routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/dashboard"
              end

              responses = Service::GetCustomizedVisualReport.new.call(spreadsheet_id: spreadsheet_id,
                                                                      visual_report_id: visual_report_id,
                                                                      visual_report: visual_report,
                                                                      config: config,
                                                                      code: code,
                                                                      access_token: access_token,
                                                                      email: @report_account["email"])

              text_responses = Service::GetTextReport.new.call(spreadsheet_id: spreadsheet_id,
                                                               visual_report_id: visual_report_id,
                                                               visual_report: visual_report,
                                                               config: config,
                                                               code: code,
                                                               access_token: access_token,
                                                               email: @report_account["email"])
              if responses.failure? || text_responses.failure?
                routing.redirect "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}/identify/score"
              end
              vis_report_object = Views::PublicVisualReport.new(visual_report, responses.value!)

              text_responses_result = text_responses.value!.to_json
              text_responses_parse = JSON.parse(text_responses_result)
              text_report_object = text_responses_parse['scores']
              # text_report_ta = text_responses_parse['ta']

              score_type = ['score_st', 'score_pr', 'score_hw', 'score_qz', 'score_la']
              categorize_score_type = text_report_object.group_by { |i| i['score_type'] }
              scores = categorize_score_type.reject{|key, value| !score_type.include? key }
              ta = categorize_score_type.select{|key, value| key == 'ta' }['ta'].first
              title = {}

              scores.each_key do |key|
                title[key] = case key
                             when 'score_st'
                               'Tutorial + Quiz (Total 2)'
                             when 'score_pr'
                               'Peer Review (Total 2)'
                             when 'score_hw'
                               'Homework (Total 5)'
                             when 'score_qz'
                               'Quiz (Total 2)'
                              when 'score_la'
                                'LA'
                             else
                               'Others'
                             end
              end

              view 'visual_report', layout: false, locals: { visual_report_id: visual_report_id,
                                                             spreadsheet_id: spreadsheet_id,
                                                             vis_report_object: vis_report_object,
                                                             visual_report: visual_report,
                                                             text_report_object: text_report_object,
                                                             title: title,
                                                             scores: scores,
                                                             ta: ta }
            end
          end

           # POST visual_report/[visual_report_id]/online/[spreadsheet_id]
          routing.post do
            redis = RedisCache.new(config)
            cache_key = "#{config.APP_URL}/visual_report/#{visual_report_id}/online/#{spreadsheet_id}"

            # redis = RedisCache.new(config)
            if redis.get('system_access_token').equal? nil
              new_access_token = Google::Auth.new(config).refresh_access_token
              redis.set('system_access_token', new_access_token, 3000)
            end
            access_token = redis.get('system_access_token')

            update_visual_report = Service::UpdateVisualReport.new
                                                              .call(redis: redis,
                                                                    visual_report_id: visual_report_id,
                                                                    spreadsheet_id: spreadsheet_id,
                                                                    config: config,
                                                                    cache_key: cache_key,
                                                                    access_token: access_token)

            flash[:error] = 'Failed to update visual report, please try again :(' if update_visual_report.failure?
            routing.redirect '/analytics'
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

      routing.on 'text_report', String do |text_report_id|
        @current_account = SecureSession.new(session).get(:current_account)
        routing.on 'online', String do |spreadsheet_id|
          # customized text report
          # GET text_report/[text_report_id]/online/[spreadsheet_id]
          routing.get do
            code = routing.params['code']

            visual_report = Repository::For[Entity::VisualReport]
                            .find_id(text_report_id)

            responses = Service::GetTextReport.new.call(spreadsheet_id: spreadsheet_id,
                                                        visual_report_id: text_report_id,
                                                        visual_report: visual_report,
                                                        config: config,
                                                        code: code,
                                                        access_token: @current_account['access_token'],
                                                        email: @current_account['email'])
            if responses.failure?
              routing.redirect "#{config.APP_URL}/text_report/#{text_report_id}/online/#{spreadsheet_id}/identify/"
            end

            text_report_object = responses.value!
            view 'text_report', layout: false, locals: { text_report_object: text_report_object}
          end
        end
      end

      # /learning_analytics branch
      routing.on 'learning_analytics' do
        @current_account = SecureSession.new(session).get(:current_account)

        # GET /learning_analytics
        routing.get do
          routing.redirect '/' unless @current_account
          visual_reports = Repository::For[Entity::VisualReport]
                           .find_owner(@current_account['id'])

          view 'learning_analytics', locals: { visual_reports: visual_reports }
        end
      end

      # /studies branch
      routing.on 'studies' do
        @current_account = SecureSession.new(session).get(:current_account)

        # POST studies/create
        routing.post 'create' do
          new_study = Service::CreateStudy.new.call(config: config,
                                                    current_account: @current_account,
                                                    params: routing.params)

          if new_study.success?
            flash[:notice] = "#{new_study.value!.title} is created!"
          else
            flash[:error] = 'Failed to create study, please try again :('
          end
          routing.redirect '/studies'
        end

        routing.on String do |study_id|
          # POST studies/[study_id]/update_title
          routing.post 'update_title' do
            Service::UpdateStudyTitle.new.call(current_account: @current_account,
                                               study_id: study_id,
                                               new_title: routing.params['title'])
            routing.redirect '/studies'
          end

          # POST studies/[study_id]/create_participant
          routing.post 'create_participant' do
            res = Service::CreateParticipant.new.call(config: config,
                                                      current_account: @current_account,
                                                      study_id: study_id,
                                                      params: routing.params)
            if res.failure?
              flash[:error] = res.failure
            else
              flash[:notice] = 'Create participants successfully!'
            end
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/confirm_noti_status
          routing.post 'confirm_noti_status' do
            res = Service::UpdateParticipantsNotiStatus.new.call(config: config, study_id: study_id)
            if res.failure?
              flash[:error] = 'Fail to update the confirmed participants. Please try again.'
            else
              flash[:notice] = 'Successfully update the confirmed participants!'
            end
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/subscribe_all
          routing.post 'subscribe_all' do
            res = Service::SubscribeAllCalendars.new.call(config: config,
                                                          current_account: @current_account,
                                                          study_id: study_id)
            if res.failure?
              flash[:error] = 'Fail to subscribe all participants. Please try again.'
            else
              flash[:notice] = 'Successfully subscribe all participants\' calendars which is open to you!'
            end
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/unsubscribe_all
          routing.post 'unsubscribe_all' do
            res = Service::UnsubscribeAllCalendars.new.call(config: config,
                                                            current_account: @current_account,
                                                            study_id: study_id)
            if res.failure?
              flash[:error] = 'Fail to unsubscribe all participants. Please try again.'
            else
              flash[:notice] = 'Successfully unsubscribe all participants!'
            end
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/create_notification
          routing.post 'create_notification' do
            res = Service::CreateNotification.new.call(config: config,
                                                       current_account: @current_account,
                                                       study_id: study_id,
                                                       params: routing.params)

            flash[:error] = 'Fail to create notification. Please try again.' if res.failure?
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/add_exist_survey
          routing.post 'add_exist_survey' do
            Service::AddExistSurvey.new.call(study_id: study_id,
                                             survey_id: routing.params['survey_id'])
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/remove_survey
          routing.post 'remove_survey' do
            Service::RemoveSurvey.new.call(config: config,
                                           study_id: study_id,
                                           survey_id: routing.params['survey_id'])
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/start_notification
          routing.post 'start_notification' do
            res = Service::StartNotification.new.call(config: config, study_id: study_id)

            if res.failure?
              flash[:error] = 'Cannot start the notificaiton. Please try again. :('
            else
              flash[:notice] = 'Successfully start the notificaiton!'
            end
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/close_notification
          routing.post 'close_notification' do
            res = Service::CloseNotification.new.call(config: config, study_id: study_id)

            if res.failure?
              flash[:error] = 'Cannot close the notificaiton. Please try again. :('
            else
              flash[:notice] = 'Successfully close the notificaiton!'
            end
            routing.redirect "/studies/#{study_id}"
          end

          # POST studies/[study_id]/update
          routing.post 'update' do
            res = Service::UpdateStudy.new.call(config: config, study_id: study_id,
                                                current_account: @current_account,
                                                params: routing.params)

            if res.failure?
              flash[:error] = 'Cannot update the study. Please try again. :('
            else
              flash[:notice] = 'Successfully update the study!'
            end
            routing.redirect "/studies/#{study_id}"
          end

          # GET studies/[study_id]/study_result_detail
          routing.on 'study_result_detail' do
            routing.get do
              result_detail = Service::GetStudyResultDetail.new.call(study_id: study_id)
              if result_detail.failure?
                puts result_detail.failure
                []
              else
                result_detail.value!
              end
            end
          end

          # POST studies/[study_id]/download/[file_name]
          routing.on 'download', String do |file_name|
            routing.post do
              response['Content-Type'] = 'application/csv'
              params = routing.params
              response = if params['result_type'] == 'responses'
                           Service::TransformResponsesToCSV.new.call(launch_id: params['wave_id'],
                                                                     participant_id: params['participant_id'])
                         elsif params['info_details_or_events'] == 'events'
                           Service::TransformEventsToCSV.new.call(study_id: study_id,
                                                                  participant_id: params['participant_id'])
                         else
                           Service::TransformParticipantsToCSV.new.call(study_id: study_id,
                                                                        participant_id: params['participant_id'])
                         end

              response.success? ? response.value! : response.failure
            end
          end

          # DELETE studies/[study_id]
          routing.delete do
            response = Service::DeleteStudy.new.call(config: config,
                                                     current_account: @current_account,
                                                     study_id: study_id)
            flash[:error] = 'Failed to delete the study. Please try again :(' if response.failure?
            routing.redirect '/studies', 303
          end

          # GET /studies/[study_id]
          routing.get do
            routing.redirect '/' unless @current_account
            study = Repository::For[Entity::Study].find_id(study_id)
            alone_surveys = Repository::For[Entity::Survey].find_alone(@current_account['id'])
            participants = Repository::For[Entity::Participant].find_study(study_id)
            notifications = Service::GetNotifications.new.call(study_id: study_id).value!
            view 'study', locals: { study: study,
                                    participants: participants,
                                    notifications: notifications,
                                    alone_surveys: alone_surveys,
                                    config: config }
          end
        end

        # GET /studies
        routing.get do
          routing.redirect '/' unless @current_account
          studies = Repository::For[Entity::Study].find_owner(@current_account['id'])
          view 'studies', locals: { studies: studies, config: config }
        end
      end

      # /participants branch
      routing.on 'participants' do
        @current_account = SecureSession.new(session).get(:current_account)

        routing.on String do |participant_id|
          # POST /participants/[participant_id]/update
          routing.post 'update' do
            Service::UpdateParticipant.new.call(config: config,
                                                current_account: @current_account,
                                                participant_id: participant_id,
                                                params: routing.params)
            routing.redirect "/participants/#{participant_id}"
          end

          # POST /participants/[participant_id]/turn_off_notify
          routing.post 'turn_off_notify' do
            Service::TurnOffNotify.new.call(config: config,
                                            participant_id: participant_id)
            routing.redirect "/participants/#{participant_id}"
          end

          # POST /participants/[participant_id]/turn_on_notify
          routing.post 'turn_on_notify' do
            Service::TurnOnNotify.new.call(config: config,
                                           participant_id: participant_id)
            routing.redirect "/participants/#{participant_id}"
          end

          # POST /participants/[participant_id]/subscribe_calendar
          routing.post 'subscribe_calendar' do
            res = Service::SubscribeCalendar.new.call(config: config,
                                                      current_account: @current_account,
                                                      participant_id: participant_id,
                                                      calendar_id: routing.params['calendar_id'])
            if res.failure?
              flash[:error] = 'Participant doesn\'t open calendar to you or give a wrong gmail address.'
            else
              flash[:notice] = 'Successfully subscribe participant!'
            end
            routing.redirect "/participants/#{participant_id}"
          end

          # POST /participants/[participant_id]/unsubscribe_calendar
          routing.post 'unsubscribe_calendar' do
            res = Service::UnsubscribeCalendar.new.call(config: config,
                                                        current_account: @current_account,
                                                        participant_id: participant_id,
                                                        calendar_id: routing.params['calendar_id'])
            if res.failure?
              flash[:error] = 'Fail to unsubscribe. Please try again.'
            else
              flash[:notice] = 'Successfully unsubscribe participant!'
            end
            routing.redirect "/participants/#{participant_id}"
          end

          # GET /participants/[participant_id]/refresh_events
          routing.get 'refresh_events' do
            res = Service::RefreshEvents.new.call(config: config,
                                                  current_account: @current_account,
                                                  participant_id: participant_id)
            if res.failure?
              flash[:error] = 'Fail to refresh paparticipant\'s events. Please try again. :('
            else
              flash[:notice] = 'Successfully refresh participant\'s events!'
            end
            routing.redirect "/participants/#{participant_id}"
          end

          # DELETE /participants/[participant_id]
          routing.post 'deletion' do
            response = Service::DeleteParticipant.new.call(config: config,
                                                           current_account: @current_account,
                                                           participant_id: participant_id)

            flash[:error] = 'Failed to delete the participant. Please try again :(' if response.failure?
            routing.redirect "/studies/#{response.value!.study.id}", 303
          end

          # GET /participants/[participant_id]
          routing.get do
            routing.redirect '/' unless @current_account

            participant = Service::GetParticipant.new.call(participant_id: participant_id)
            events = Service::GetEvents.new.call(participant_id: participant_id)

            if participant.failure? || events.failure?
              flash[:error] = 'Failed to get the participant. Please try again :('
              routing.redirect '/studies'
            else
              view 'participant', locals: { participant: participant.value![:participant],
                                            details: participant.value![:details],
                                            events: events.value![:events],
                                            busy_time: events.value![:busy_time] }
            end
          end
        end
      end

      # /notifications branch
      routing.on 'notifications' do
        @current_account = SecureSession.new(session).get(:current_account)

        routing.on String do |notification_id|
          # DELETE /notifications/[notification_id]
          routing.post 'deletion' do
            response = Service::DeleteNotification.new.call(config: config, notification_id: notification_id)

            flash[:error] = 'Failed to delete the notification. Please try again :(' if response.failure?
            routing.redirect "/studies/#{response.value!.study.id}", 303
          end

          # GET /notifications/[notification_id]
          routing.get do
            routing.redirect '/' unless @current_account

            notification = Service::GetNotification.new.call(notification_id: notification_id)
            view 'notification', locals: { notification: notification.value![:notification],
                                           date_time: notification.value![:date_time],
                                           config: config }
          end
        end
      end
    end
  end
  # rubocop: enable Metrics/ClassLength
  # rubocop: enable Metrics/BlockLength
end
