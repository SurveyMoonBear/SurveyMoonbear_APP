# frozen_string_literal: false

require_relative './spec_helper.rb'

describe 'Tests of Integration Services Related to GoogleSpreadsheetAPI' do
  before(:all) do
    VcrHelper.setup_vcr
    DatabaseHelper.setup_database_cleaner
    VcrHelper.configure_vcr_for_gs
    @survey = SurveyMoonbear::CreateSurvey.new.call(config: CONFIG, current_account: CURRENT_ACCOUNT, 
                                                    title: 'Survey for Testing Integration Services').value!
  end

  after(:all) do
    SurveyMoonbear::DeleteSurvey.new.call(config: CONFIG, survey_id: @survey.id)
    DatabaseHelper.wipe_database
    VcrHelper.eject_vcr
  end

  it 'HAPPY: should be able to preview survey questions in HTML' do
    result = SurveyMoonbear::PreviewSurveyInHTML.new.call(survey_id: @survey.id, 
                                                          current_account: CURRENT_ACCOUNT)
    _(result.success?).must_equal true
    _(result.value![:questions][0]).wont_be :empty?
  end

  it 'SAD: should get failure on invalid survey id when trying to preview survey HTML' do
    result = SurveyMoonbear::PreviewSurveyInHTML.new.call(survey_id: 'invalid_survey_id', 
                                                          current_account: CURRENT_ACCOUNT)
    _(result.failure?).must_equal true
  end

  it 'HAPPY: should be able to get survey and start/close it' do
    started_result = SurveyMoonbear::GetSurveyToStart.new.call(survey_id: @survey.id, current_account: CURRENT_ACCOUNT)
    _(started_result.success?).must_equal true
    _(started_result.value!.state).must_equal 'started'

    closed_result = SurveyMoonbear::GetSurveyAndClose.new.call(survey_id: @survey.id)
    _(closed_result.success?).must_equal true
    _(closed_result.value!.state).must_equal 'closed'
    _(closed_result.value!.id).must_equal(started_result.value!.launch_id)
  end
end