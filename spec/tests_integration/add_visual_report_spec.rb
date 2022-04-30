# frozen_string_literal: false

require_relative './../spec_helper'
# require_relative './../../workers/responses_store_worker'

describe 'HAPPY: Tests of Services Related to GoogleSpreadsheetAPI & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gs
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Copy & Create visual report' do
    before do
      VcrHelper.build_cassette('happy_create_visual_report')
    end

    after do
      SurveyMoonbear::Service::DeleteVisualReport.new.call(config: CONFIG, visual_report_id: @new_visreport_res.value!.id)
    end

    it 'HAPPY: should copy sample and create visual report with provided title' do
      @new_visreport_res = SurveyMoonbear::Service::CreateVisualReport.new.call(config: CONFIG,
                                                                                current_account: CURRENT_ACCOUNT,
                                                                                title: 'Visual Report for Testing Create Services')
      _(@new_visreport_res.success?).must_equal true
      _(@new_visreport_res.value!.owner.username).must_equal 'SurveyMoonbear Test'
    end
  end

  describe 'Delete visual report' do
    before do
      VcrHelper.build_cassette('happy_delete_visual_report')
      @visreport = SurveyMoonbear::Service::CreateVisualReport.new.call(config: CONFIG,
                                                                        current_account: CURRENT_ACCOUNT,
                                                                        title: 'Visual Report for Testing Delete Services').value!
    end

    it 'HAPPY: should delete the visual report in both db and spreadsheet' do
      deleted_visreport_res = SurveyMoonbear::Service::DeleteVisualReport.new.call(config: CONFIG, visual_report_id: @visreport.id)
      _(deleted_visreport_res.success?).must_equal true
      _(deleted_visreport_res.value!.id).must_equal @visreport.id
    end
  end
end
