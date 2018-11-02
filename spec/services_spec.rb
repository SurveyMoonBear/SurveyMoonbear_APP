require_relative './spec_helper.rb'

describe 'Service tests' do
  # Execute before/after each 'describe'
  before(:all) do
    DatabaseHelper.setup_database_cleaner
  end

  after(:all) do
    DatabaseHelper.wipe_database
  end

  describe 'Create survey' do
    it 'HAPPY: should create survey with provided title' do
      new_survey = SurveyMoonbear::CreateSurvey.new(CURRENT_ACCOUNT, CONFIG).call('New Survey')
      _(new_survey.owner.username).must_equal 'SurveyMoonbear Test'
      _(new_survey.title).must_equal 'New Survey'
      _(new_survey.pages).wont_be :empty?
      _(new_survey.pages[0].items).wont_be :empty?
    end
  end

  describe 'Delete survey' do
    before do
      @survey = SurveyMoonbear::CreateSurvey.new(CURRENT_ACCOUNT, CONFIG).call('Survey for test')
    end

    it 'HAPPY: should delete the survey in both db and spreadsheet' do
      deleted_survey = SurveyMoonbear::DeleteSurvey.new(CURRENT_ACCOUNT, CONFIG).call(@survey.id)
      _(deleted_survey.id).must_equal @survey.id
      assert_nil SurveyMoonbear::GetSurveyFromDatabase.new.call(@survey.id)
      proc do
        SurveyMoonbear::GetSurveyFromSpreadsheet.new(CURRENT_ACCOUNT).call(@survey.origin_id)
      end.must_raise SurveyMoonbear::Google::Api::Errors::NotFound
    end
  end

  describe 'Retrieve surveys and make changes' do
    before(:all) do
      @survey = SurveyMoonbear::CreateSurvey.new(CURRENT_ACCOUNT, CONFIG).call('Survey for test')
    end

    it 'HAPPY: should get survey from database' do
      saved_survey = SurveyMoonbear::GetSurveyFromDatabase.new.call(@survey.id)
      _(saved_survey.owner.username).must_equal 'SurveyMoonbear Test'
      _(saved_survey.pages).wont_be :empty?
      _(saved_survey.pages[0].items).wont_be :empty?
    end

    it 'HAPPY: should get survey from spreadsheet' do
      gs_survey = SurveyMoonbear::GetSurveyFromSpreadsheet.new(CURRENT_ACCOUNT).call(@survey.origin_id)
      _(gs_survey.owner.username).must_equal 'SurveyMoonbear Test'
      _(gs_survey.pages).wont_be :empty?
      _(gs_survey.pages[0].items).wont_be :empty?
    end

    it 'SAD: should raise exception on invalid spreadsheet_id when getting survey from spreadsheet' do
      proc do
        SurveyMoonbear::GetSurveyFromSpreadsheet.new(CURRENT_ACCOUNT).call('invalid_spreadsheet_id')
      end.must_raise SurveyMoonbear::Google::Api::Errors::NotFound
    end

    it 'HAPPY: should be able to edit survey title' do
      editted_survey = SurveyMoonbear::EditSurveyTitle.new(CURRENT_ACCOUNT)
                                                      .call(@survey.id, {'title' => 'New title'})
      _(editted_survey.title).must_equal 'New title'
    end

    it 'HAPPY: should start/close survey' do
      started_survey = SurveyMoonbear::StartSurvey.new.call(@survey)
      _(started_survey.state).must_equal 'started'
      _(started_survey.launch_id).wont_be_nil

      closed_launch = SurveyMoonbear::CloseSurvey.new.call(started_survey)
      _(closed_launch.state).must_equal 'closed'
      _(closed_launch.id).must_equal started_survey.launch_id
    end
  end
end
