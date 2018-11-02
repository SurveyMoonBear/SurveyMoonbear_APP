require_relative './spec_helper.rb'

describe 'Integration service tests' do
  before(:all) do
    DatabaseHelper.setup_database_cleaner
    @survey = SurveyMoonbear::CreateSurvey.new(CURRENT_ACCOUNT, CONFIG).call('Survey for test')
  end

  after(:all) do
    DatabaseHelper.wipe_database
  end

  it 'HAPPY: should be able to preview survey questions in HTML' do
    result = SurveyMoonbear::PreviewSurveyInHTML.new.with_step_args(get_survey_from_spreadsheet: [CURRENT_ACCOUNT])
                                                    .call(@survey.id)
    _(result.success?).must_equal true
    _(result.value![:questions][0]).wont_be :empty?
  end

  it 'SAD: should get failure on invalid survey id when trying to preview survey HTML' do
    result = SurveyMoonbear::PreviewSurveyInHTML.new.with_step_args(get_survey_from_spreadsheet: [CURRENT_ACCOUNT])
                                                    .call('invalid_survey_id')
    _(result.failure?).must_equal true
  end

  it 'HAPPY: should be able to get survey and start/close it' do
    started_result = SurveyMoonbear::GetSurveyToStart.new.with_step_args(get_survey_from_spreadsheet: [CURRENT_ACCOUNT])
                                                         .call(@survey.id)
    _(started_result.success?).must_equal true
    _(started_result.value!.state).must_equal 'started'

    closed_result = SurveyMoonbear::GetSurveyAndClose.new.call(@survey.id)
    _(closed_result.success?).must_equal true
    _(closed_result.value!.state).must_equal 'closed'
    _(closed_result.value!.id).must_equal(started_result.value!.launch_id)
  end
end