# frozen_string_literal: false

require_relative './spec_helper.rb'

describe 'HAPPY: Tests of Services Related to GoogleSpreadsheetAPI & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    DatabaseHelper.setup_database_cleaner
    VcrHelper.configure_vcr_for_gs
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Create survey' do
    before do
      VcrHelper.build_cassette('happy_create_gs_api')
    end

    after do
      SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @new_survey_res.value!.id)
    end

    it 'HAPPY: should create survey with provided title' do
      @new_survey_res = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG, 
                                                                       current_account: CURRENT_ACCOUNT, 
                                                                       title: 'Survey for Testing Create Services')
      _(@new_survey_res.success?).must_equal true
      _(@new_survey_res.value!.owner.username).must_equal 'SurveyMoonbear Test'
      _(@new_survey_res.value!.pages).wont_be :empty?
      _(@new_survey_res.value!.pages[0].items).wont_be :empty?
    end
  end

  describe 'Delete survey' do
    before do
      VcrHelper.build_cassette('happy_delete_gs_api')
      @survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG, 
                                                               current_account: CURRENT_ACCOUNT, 
                                                               title: 'Survey for Testing Delete Services').value!
    end

    it 'HAPPY: should delete the survey in both db and spreadsheet' do
      deleted_survey_res = SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @survey.id)
      _(deleted_survey_res.success?).must_equal true
      _(deleted_survey_res.value!.id).must_equal @survey.id
    end
  end

  describe 'After survey created: retrieve surveys and make changes' do
    before(:all) do
      VcrHelper.build_cassette('happy_change_gs_api')
      @survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG, 
                                                               current_account: CURRENT_ACCOUNT, 
                                                               title: 'Survey for Testing Changes Services').value!
    end

    after(:all) do
      SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @survey.id)
    end

    it 'HAPPY: should get survey from database' do
      get_db_survey_res = SurveyMoonbear::Service::GetSurveyFromDatabase.new.call(survey_id: @survey.id)
      _(get_db_survey_res.success?).must_equal true
      _(get_db_survey_res.value!.owner.username).must_equal 'SurveyMoonbear Test'
      _(get_db_survey_res.value!.pages).wont_be :empty?
    end

    it 'HAPPY: should get survey from spreadsheet' do
      get_gs_survey_res = SurveyMoonbear::Service::GetSurveyFromSpreadsheet.new.call(spreadsheet_id: @survey.origin_id, 
                                                                                     current_account: CURRENT_ACCOUNT)
      _(get_gs_survey_res.success?).must_equal true
      _(get_gs_survey_res.value!.owner.username).must_equal 'SurveyMoonbear Test'
      _(get_gs_survey_res.value!.pages).wont_be :empty?
      _(get_gs_survey_res.value!.pages[0].items).wont_be :empty?
    end

    it 'HAPPY: should be able to edit survey title' do
      editted_survey_res = SurveyMoonbear::Service::EditSurveyTitle.new.call(current_account: CURRENT_ACCOUNT, 
                                                                             survey_id: @survey.id, 
                                                                             new_title: "New title")
      _(editted_survey_res.success?).must_equal true
    end

    it 'HAPPY: should start/close survey' do
      started_survey_res = SurveyMoonbear::Service::StartSurvey.new.call(survey_id: @survey.id, 
                                                                         current_account: CURRENT_ACCOUNT)
      _(started_survey_res.success?).must_equal true
      _(started_survey_res.value!.state).must_equal 'started'
      _(started_survey_res.value!.launch_id).wont_be_nil

      closed_launch_res = SurveyMoonbear::Service::CloseSurvey.new.call(survey_id: started_survey_res.value!.id)
      _(closed_launch_res.success?).must_equal true
      _(closed_launch_res.value!.state).must_equal 'closed'
    end
  end

  describe 'After survey started: output surveys and handle responses' do
    before(:all) do
      VcrHelper.build_cassette('happy_output_responses')
      survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG, current_account: CURRENT_ACCOUNT, title: 'Survey for Testing').value!
      @started_survey = SurveyMoonbear::Service::StartSurvey.new.call(survey_id: survey.id, 
                                                                      current_account: CURRENT_ACCOUNT).value!
    end

    after(:all) do
      SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @started_survey.id)
    end

    it 'HAPPY: should be able to view survey items in html' do
      trans_html_res = SurveyMoonbear::Service::TransformSurveyItemsToHTML.new.call(survey_id: @started_survey.id)
      _(trans_html_res.success?).must_equal true
      _(trans_html_res.value![:questions][0]).wont_be :empty?
    end

    it 'HAPPY: should be able to store responses and transform into csv' do
      respondent_id = SecureRandom.uuid
      response_params = {"moonbear_start_time"=>"Wed Nov 07 2018 09:53:06 GMT+0800 (台北標準時間)", "moonbear_end_time"=>"Wed Nov 07 2018 09:54:16 GMT+0800 (台北標準時間)", "name"=>"Respondent1", "radio-age_num"=>"10~20", "age_num"=>"10~20", "self_intro"=>"Hi, I'm Respondent1.", "checkbox-social_website"=>"Google+", "social_website"=>"Facebook, Instagram, Google+", "radio-frequency"=>"4", "frequency"=>"4", "radio-safisfaction"=>"5", "safisfaction"=>"5", "radio-needs"=>"2", "needs"=>"2", "moonbear_url_params"=>"{}"}
      stored_responses_res = SurveyMoonbear::Service::StoreResponses.new.call(survey_id: @started_survey.id, 
                                                                              launch_id: @started_survey.launch_id, 
                                                                              respondent_id: respondent_id, 
                                                                              responses: response_params,
                                                                              config: CONFIG)
      _(stored_responses_res.success?).must_equal true
      _(stored_responses_res.value!).must_be_nil

      transform_csv_res = SurveyMoonbear::Service::TransformResponsesToCSV.new.call(survey_id: @started_survey.id, 
                                                                                    launch_id: @started_survey.launch_id)
      _(transform_csv_res.success?).must_equal true
      _(transform_csv_res.value!).must_be_instance_of String
    end
  end
end
