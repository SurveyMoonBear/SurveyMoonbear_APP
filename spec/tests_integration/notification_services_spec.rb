# frozen_string_literal: false

require_relative './../spec_helper'

describe 'HAPPY: Tests of Services Related to Notification & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gs
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Create and delete notification' do
    before(:all) do
      VcrHelper.build_cassette('happy_create_notification')
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITH_NOTIFY_PARAMS).value!
      @survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG,
                                                               current_account: CURRENT_ACCOUNT,
                                                               title: 'Survey for Testing Create Notification',
                                                               study_id: @study.id).value!
    end

    after(:all) do
      SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @survey.id)
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @study.id)
    end

    describe 'Create 3 different types notifications' do
      it 'HAPPY: should create a fixed notification' do
        params = {
          'title' => 'new_fixed_noti',
          'survey_id' => @survey.id,
          'type' => 'fixed',
          'fixed_timestamp' => '2022-06-08T21:30',
          'repeat_every' => 'day',
          'repeat_on' => '',
          'repeat_at' => 'set_time',
          'repeat_set_time' => '',
          'repeat_random_start' => '',
          'repeat_random_end' => '',
          'content' => 'please fill in XXXX'
        }
        @new_fixed = SurveyMoonbear::Service::CreateNotification.new.call(config: CONFIG,
                                                                          current_account: CURRENT_ACCOUNT,
                                                                          study_id: @study.id,
                                                                          params: params)
        _(@new_fixed.success?).must_equal true
        _(@new_fixed.value!.title).must_equal params['title']
        _(@new_fixed.value!.fixed_timestamp).must_equal Time.parse(params['fixed_timestamp'])
      end

      it 'HAPPY: should create repeat at set time notification' do
        params = {
          'title' => 'repeat at set time notification',
          'survey_id' => @survey.id,
          'type' => 'repeating',
          'fixed_timestamp' => '',
          'repeat_every' => 'day',
          'repeat_on' => '',
          'repeat_at' => 'set_time',
          'repeat_set_time' => '00:00',
          'repeat_random_start' => '',
          'repeat_random_end' => '',
          'content' => 'please fill in'
        }
        @new_set_time = SurveyMoonbear::Service::CreateNotification.new.call(config: CONFIG,
                                                                             current_account: CURRENT_ACCOUNT,
                                                                             study_id: @study.id,
                                                                             params: params)
        _(@new_set_time.success?).must_equal true
        _(@new_set_time.value!.title).must_equal params['title']
        _(@new_set_time.value!.repeat_at).must_equal params['repeat_at']
        _(@new_set_time.value!.repeat_set_time).must_equal '00 00 * * *'
      end

      it 'HAPPY: should create repeat at random time notification' do
        params = {
          'title' => 'repeat at random time',
          'survey_id' => @survey.id,
          'type' => 'repeating',
          'fixed_timestamp' => '',
          'repeat_every' => 'day',
          'repeat_on' => '',
          'repeat_at' => 'random',
          'repeat_set_time' => '',
          'repeat_random_start' => '00:00',
          'repeat_random_end' => '12:00',
          'content' => 'please fill in'
        }
        @new_random_time = SurveyMoonbear::Service::CreateNotification.new.call(config: CONFIG,
                                                                                current_account: CURRENT_ACCOUNT,
                                                                                study_id: @study.id,
                                                                                params: params)
        _(@new_random_time.success?).must_equal true
        _(@new_random_time.value!.title).must_equal params['title']
        _(@new_random_time.value!.repeat_at).must_equal params['repeat_at']
        _(@new_random_time.value!.repeat_random_start).must_equal params['repeat_random_start']
        _(@new_random_time.value!.repeat_random_end).must_equal params['repeat_random_end']
      end
    end
  end

  describe 'Delete visual report' do
    before do
      VcrHelper.build_cassette('happy_delete_notification')
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITH_NOTIFY_PARAMS).value!
      @survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG,
                                                               current_account: CURRENT_ACCOUNT,
                                                               title: 'Survey for Testing Delete Notification',
                                                               study_id: @study.id).value!
      params = {
        'title' => 'new_fixed_noti',
        'survey_id' => @survey.id,
        'type' => 'fixed',
        'fixed_timestamp' => '2022-06-08T21:30',
        'repeat_every' => 'day',
        'repeat_on' => '',
        'repeat_at' => 'set_time',
        'repeat_set_time' => '',
        'repeat_random_start' => '',
        'repeat_random_end' => '',
        'content' => 'please fill in XXXX'
      }
      @new_noti = SurveyMoonbear::Service::CreateNotification.new.call(config: CONFIG,
                                                                       current_account: CURRENT_ACCOUNT,
                                                                       study_id: @study.id,
                                                                       params: params).value!
    end

    after do
      SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @survey.id)
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @study.id)
    end

    it 'HAPPY: should delete notification' do
      deleted_notification = SurveyMoonbear::Service::DeleteNotification.new.call(config: CONFIG,
                                                                                  notification_id: @new_noti.id)
      _(deleted_notification.success?).must_equal true
      _(deleted_notification.value!.id).must_equal @new_noti.id
    end
  end
end
