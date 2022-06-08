# frozen_string_literal: false

require_relative './../spec_helper'

describe 'HAPPY: Tests of Services Related to GoogleCalendarAPI & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gs
    @study = SurveyMoonbear::Service::CreateStudy.new.call(config: CONFIG,
                                                           current_account: CURRENT_ACCOUNT,
                                                           params: CALENDAR_TEST_STUDY).value!
    @participant = SurveyMoonbear::Service::CreateParticipant.new.call(config: CONFIG,
                                                                       current_account: CURRENT_ACCOUNT,
                                                                       study_id: @study.id,
                                                                       params: CALENDAR_TEST_PARTICIPANT).value!
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Subscribe calendar' do
    before do
      VcrHelper.build_cassette('happy_subscribe_calendar')
    end

    after do
      SurveyMoonbear::Service::UnsubscribeCalendar.new.call(config: CONFIG,
                                                            current_account: CURRENT_ACCOUNT,
                                                            participant_id: @participant.id,
                                                            calendar_id: CALENDAR_ID)
    end

    it 'HAPPY: should subscribe the calendar' do
      @new_subscription_res = SurveyMoonbear::Service::SubscribeCalendar.new.call(config: CONFIG,
                                                                                  current_account: CURRENT_ACCOUNT,
                                                                                  participant_id: @participant.id,
                                                                                  calendar_id: CALENDAR_ID)
      _(@new_subscription_res.success?).must_equal true
      _(@new_subscription_res.value!.act_status).must_equal 'subscribed'
    end
  end

  describe 'Refresh events from calendar' do
    before do
      VcrHelper.build_cassette('happy_refresh_events')
      SurveyMoonbear::Service::SubscribeCalendar.new.call(config: CONFIG,
                                                          current_account: CURRENT_ACCOUNT,
                                                          participant_id: @participant.id,
                                                          calendar_id: CALENDAR_ID)
    end

    after do
      SurveyMoonbear::Service::UnsubscribeCalendar.new.call(config: CONFIG,
                                                            current_account: CURRENT_ACCOUNT,
                                                            participant_id: @participant.id,
                                                            calendar_id: CALENDAR_ID)
    end

    it 'HAPPY: should get all the events from the participant calendar' do
      @new_events_res = SurveyMoonbear::Service::RefreshEvents.new.call(config: CONFIG,
                                                                        current_account: CURRENT_ACCOUNT,
                                                                        participant_id: @participant.id)
      _(@new_events_res.success?).must_equal true
      _(@new_events_res.value!).must_be_instance_of Array
    end
  end

  describe 'Unsubscribe calendar' do
    before do
      VcrHelper.build_cassette('happy_unsubscribe_calendar')
      SurveyMoonbear::Service::SubscribeCalendar.new.call(config: CONFIG,
                                                          current_account: CURRENT_ACCOUNT,
                                                          participant_id: @participant.id,
                                                          calendar_id: CALENDAR_ID)
    end

    it 'HAPPY: should unsubscribe the calendar' do
      unsubscribe_calendar = SurveyMoonbear::Service::UnsubscribeCalendar.new.call(config: CONFIG,
                                                                                   current_account: CURRENT_ACCOUNT,
                                                                                   participant_id: @participant.id,
                                                                                   calendar_id: CALENDAR_ID)
      _(unsubscribe_calendar.success?).must_equal true
      _(unsubscribe_calendar.value!.act_status).must_equal 'unsubscribed'
    end
  end
end
