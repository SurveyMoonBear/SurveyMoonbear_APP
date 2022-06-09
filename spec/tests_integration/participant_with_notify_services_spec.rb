# frozen_string_literal: false

require_relative './../spec_helper'

describe 'HAPPY: Tests of Services Related to Participant with notify & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gs
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Update participant notification status with fake data' do
    before(:all) do
      VcrHelper.build_cassette('happy_update_participant_with_notify')
      @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                             current_account: CURRENT_ACCOUNT,
                                                             params: STUDY_WITH_NOTIFY_PARAMS).value!
      @parti = SurveyMoonbear::Service::CreateParticipant.new.call(config: CONFIG,
                                                                   current_account: CURRENT_ACCOUNT,
                                                                   study_id: @study.id,
                                                                   params: PARTICIPANT_WITH_NOTIFY_PARAMS).value!
    end

    after(:all) do
      SurveyMoonbear::Service::DeleteStudy.new.call(config: CONFIG,
                                                    current_account: CURRENT_ACCOUNT,
                                                    study_id: @study.id)
    end

    describe 'Confirm participant notification status' do
      it 'HAPPY: should confirm participant notification status' do
        @new_parti = SurveyMoonbear::Service::ConfirmParticipantsNotiStatus.new.call(config: CONFIG,
                                                                                     study: @study,
                                                                                     participant: @parti,
                                                                                     arn: 'aws:arn:for:test:confirm')
        _(@new_parti.success?).must_equal true
        _(@new_parti.value!.noti_status).must_equal 'confirmed'
        _(@new_parti.value!.aws_arn).must_equal 'aws:arn:for:test:confirm'
      end
    end

    describe 'Pending participant notification status' do
      it 'HAPPY: should get pending participant notification status' do
        @new_parti = SurveyMoonbear::Service::PendingParticipantsNotiStatus.new.call(config: CONFIG,
                                                                                     study: @study,
                                                                                     participant: @parti)
        _(@new_parti.success?).must_equal true
        _(@new_parti.value!.noti_status).must_equal 'pending'
        _(@new_parti.value!.aws_arn).must_equal 'pending confirmation'
      end
    end

    describe 'Turn off participant notification status' do
      before do
        @parti = SurveyMoonbear::Service::ConfirmParticipantsNotiStatus.new.call(config: CONFIG,
                                                                                 study: @study,
                                                                                 participant: @parti,
                                                                                 arn: 'aws:arn:for:test:confirm').value!
      end

      it 'HAPPY: should turn off participant notification status' do
        @new_parti = SurveyMoonbear::Service::TurnOffNotify.new.call(config: CONFIG, participant_id: @parti.id)
        _(@new_parti.success?).must_equal true
        _(@new_parti.value!.noti_status).must_equal 'turn_off'
        _(@new_parti.value!.aws_arn).must_include 'aws'
      end
    end

    describe 'Turn on participant notification status' do
      before do
        @parti = SurveyMoonbear::Service::ConfirmParticipantsNotiStatus.new.call(config: CONFIG,
                                                                                 study: @study,
                                                                                 participant: @parti,
                                                                                 arn: 'aws:arn:for:test:confirm').value!
        @parti = SurveyMoonbear::Service::TurnOffNotify.new.call(config: CONFIG, participant_id: @parti.id).value!
      end

      it 'HAPPY: should turn on participant notification status' do
        @new_parti = SurveyMoonbear::Service::TurnOnNotify.new.call(config: CONFIG, participant_id: @parti.id)
        _(@new_parti.success?).must_equal true
        _(@new_parti.value!.noti_status).must_equal 'confirmed'
        _(@new_parti.value!.aws_arn).must_include 'aws'
      end
    end

    describe 'Update participant notification status from AWS' do

      it 'HAPPY: should update participant notification status from AWS' do
        @new_parti = SurveyMoonbear::Service::UpdateParticipantsNotiStatus.new.call(config: CONFIG, study_id: @study.id)
        _(@new_parti.success?).must_equal true
        _(@new_parti.value!).must_be_instance_of Array
        _(@new_parti.value![0].aws_arn).must_equal 'pending confirmation'
      end
    end
  end
end
