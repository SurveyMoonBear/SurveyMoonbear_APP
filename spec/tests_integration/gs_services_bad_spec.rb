# frozen_string_literal: false

require_relative './../spec_helper'

describe 'BAD: Tests of Services Related to GoogleSpreadsheetAPI & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gs
    VcrHelper.build_cassette('bad_gs_api')
  end

  after(:all) do
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  describe 'Retrieve surveys and make changes' do
    it 'BAD: should raise exception on invalid spreadsheet_id when getting survey from spreadsheet' do
      get_gs_survey_res = SurveyMoonbear::Service::GetSurveyFromSpreadsheet.new.call(spreadsheet_id: 'invalid_spreadsheet_id', 
                                                                                     access_token: ACCESS_TOKEN,
                                                                                     owner: CURRENT_ACCOUNT)
      _(get_gs_survey_res.failure?).must_equal true
    end

    it 'BAD: should get failure on invalid survey id when trying to view survey HTML' do
      result = SurveyMoonbear::Service::TransformDBSurveyToHTML.new.call(survey_id: 'invalid_survey_id', 
                                                                         random_seed: nil)
      _(result.failure?).must_equal true
    end
  end
end