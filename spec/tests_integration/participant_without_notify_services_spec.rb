# frozen_string_literal: false

require_relative './../spec_helper'

describe 'HAPPY: Tests of Services Related to Participant without notify & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gs
    @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                           current_account: CURRENT_ACCOUNT,
                                                           params: STUDY_PARAMS).value!
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Create participant without notify' do
    before do
      VcrHelper.build_cassette('happy_create_participant_without_notify')
    end

    after do
      SurveyMoonbear::Service::DeleteParticipant.new.call(config: CONFIG,
                                                          current_account: CURRENT_ACCOUNT,
                                                          participant_id: @new_participant.value!.id)
    end

    it 'HAPPY: should create a new participant without notify' do
      @new_participant = SurveyMoonbear::Service::CreateParticipant.new.call(config: CONFIG,
                                                                             current_account: CURRENT_ACCOUNT,
                                                                             study_id: @study.id,
                                                                             params: PARTICIPANT_WITHOUT_NOTIFY_PARAMS)
      _(@new_participant.success?).must_equal true
      _(@new_participant.value!.nickname).must_equal PARTICIPANT_WITHOUT_NOTIFY_PARAMS['nickname']
    end
  end

  describe 'Update participant without notify' do
    before do
      VcrHelper.build_cassette('happy_update_participant_without_notify')
      @participant = SurveyMoonbear::Service::CreateParticipant.new.call(config: CONFIG,
                                                                         current_account: CURRENT_ACCOUNT,
                                                                         study_id: @study.id,
                                                                         params: PARTICIPANT_WITHOUT_NOTIFY_PARAMS).value!
    end

    after do
      SurveyMoonbear::Service::DeleteParticipant.new.call(config: CONFIG,
                                                          current_account: CURRENT_ACCOUNT,
                                                          participant_id: @participant.id)
    end

    it 'HAPPY: should update participant nickname & email without notify' do
      new_params = {
        'nickname' => 'update new participant nickname',
        'contact_type' => 'email',
        'email' => 'update_new_email@gmail.com',
        'phone' => '',
        'details' => '',
        'aws_arn' => 'disable notification',
        'noti_status' => 'disabled'
      }
      @new_parti = SurveyMoonbear::Service::UpdateParticipant.new.call(config: CONFIG,
                                                                       current_account: CURRENT_ACCOUNT,
                                                                       participant_id: @participant.id,
                                                                       params: new_params)
      _(@new_parti.success?).must_equal true
      _(@new_parti.value!.nickname).must_equal new_params['nickname']
      _(@new_parti.value!.email).must_equal new_params['email']
    end
  end

  describe 'Delete participant without notify' do
    before do
      VcrHelper.build_cassette('happy_delete_participant_without_notify')
      @participant = SurveyMoonbear::Service::CreateParticipant.new.call(config: CONFIG,
                                                                         current_account: CURRENT_ACCOUNT,
                                                                         study_id: @study.id,
                                                                         params: PARTICIPANT_WITHOUT_NOTIFY_PARAMS).value!
    end

    it 'HAPPY: should delete participant without notify' do
      deleted_participant = SurveyMoonbear::Service::DeleteParticipant.new.call(config: CONFIG,
                                                                                current_account: CURRENT_ACCOUNT,
                                                                                participant_id: @participant.id)
      _(deleted_participant.success?).must_equal true
      _(deleted_participant.value!.id).must_equal @participant.id
    end
  end
end
