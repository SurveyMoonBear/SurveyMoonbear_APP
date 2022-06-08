# frozen_string_literal: false

require_relative './../spec_helper'

describe 'HAPPY: Tests of Services Related to Study & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gs
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Create study' do
    before do
      VcrHelper.build_cassette('happy_create_study')
    end

    after do
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @new_study.value!.id)
    end

    it 'HAPPY: should create a new study' do
      @new_study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                                 current_account: CURRENT_ACCOUNT,
                                                                 params: STUDY_WITHOUT_NOTIFY_PARAMS)
      _(@new_study.success?).must_equal true
      _(@new_study.value!.title).must_equal STUDY_WITHOUT_NOTIFY_PARAMS['title']
    end
  end

  describe 'Update study title' do
    before do
      VcrHelper.build_cassette('happy_update_study_title')
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITHOUT_NOTIFY_PARAMS).value!
    end

    after do
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @study.id)
    end

    it 'HAPPY: should update study new title' do
      new_title = 'update new study title'
      @new_study = SurveyMoonbear::Service::UpdateStudyTitle.new.call(current_account: CURRENT_ACCOUNT,
                                                                      study_id: @study.id,
                                                                      new_title: new_title)
      _(@new_study.success?).must_equal true
      _(@new_study.value!.title).must_equal new_title
    end
  end

  describe 'Update study with a new description and enable notification' do
    before do
      VcrHelper.build_cassette('happy_update_study_details')
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITHOUT_NOTIFY_PARAMS).value!
    end

    after do
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @study.id)
    end

    it 'HAPPY: should update study new descripion and enable notification' do
      @new_study = SurveyMoonbear::Service::UpdateStudy.new.call(config: CONFIG,
                                                                 current_account: CURRENT_ACCOUNT,
                                                                 study_id: @study.id,
                                                                 params: STUDY_WITH_NOTIFY_PARAMS)
      _(@new_study.success?).must_equal true
      _(@new_study.value!.desc).must_equal STUDY_WITH_NOTIFY_PARAMS['desc']
      _(@new_study.value!.enable_notification).must_equal STUDY_WITH_NOTIFY_PARAMS['enable_notification']
      _(@new_study.value!.aws_arn).must_include 'arn:aws:sns'
    end
  end

  describe 'Add exist survey into study' do
    before do
      VcrHelper.build_cassette('happy_add_exist_survey_into_study')
      @survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG,
                                                               current_account: CURRENT_ACCOUNT,
                                                               title: 'Survey for Testing Delete Services').value!
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITHOUT_NOTIFY_PARAMS).value!
    end

    after do
      SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @survey.id)
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @study.id)
    end

    it 'HAPPY: should add an exist survey into study' do
      @added_survey = SurveyMoonbear::Service::AddExistSurvey.new.call(study_id: @study.id, survey_id: @survey.id)
      _(@added_survey.success?).must_equal true
      _(@added_survey.value!.title).must_equal @survey.title
    end
  end

  describe 'Remove survey from study' do
    before do
      VcrHelper.build_cassette('happy_remove_survey_from_study')
      @survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG,
                                                               current_account: CURRENT_ACCOUNT,
                                                               title: 'Survey for Testing Delete Services').value!
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITHOUT_NOTIFY_PARAMS).value!
      SurveyMoonbear::Service::AddExistSurvey.new.call(study_id: @study.id, survey_id: @survey.id)
    end

    after do
      SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @survey.id)
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @study.id)
    end

    it 'HAPPY: should remove survey from study' do
      @removed_survey = SurveyMoonbear::Service::AddExistSurvey.new.call(study_id: @study.id, survey_id: @survey.id)
      _(@removed_survey.success?).must_equal true
      _(@removed_survey.value!.title).must_equal @survey.title
    end
  end

  describe 'Delete study' do
    before do
      VcrHelper.build_cassette('happy_delete_study')
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITHOUT_NOTIFY_PARAMS).value!
    end

    it 'HAPPY: should delete study' do
      deleted_study = SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                                    current_account: CURRENT_ACCOUNT,
                                                                    study_id: @study.id)
      _(deleted_study.success?).must_equal true
      _(deleted_study.value!.id).must_equal @study.id
    end
  end
end
