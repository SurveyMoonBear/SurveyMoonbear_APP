# frozen_string_literal: false

require_relative './spec_helper.rb'

describe 'BAD: Tests of Services Related to GoogleSpreadsheetAPI & Database' do
  # Execute before/after each 'describe'
  before(:all) do
    VcrHelper.setup_vcr
    DatabaseHelper.setup_database_cleaner
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
                                                                                     current_account: CURRENT_ACCOUNT)
      _(get_gs_survey_res.failure?).must_equal true
    end

    it 'BAD: should get failure on invalid survey id when trying to view survey HTML' do
      result = SurveyMoonbear::Service::TransformSurveyItemsToHTML.new.call(survey_id: 'invalid_survey_id', 
                                                                            current_account: CURRENT_ACCOUNT)
      _(result.failure?).must_equal true
    end
  end
end