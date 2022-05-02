# frozen_string_literal: false

require_relative './spec_helper.rb'

# Access response-storing SQS without VCR
# Reason: Cannot use VCR to test real SQS msg sending (due to the MD5 message digest of SQS msg)
describe 'HAPPY: Tests of Responses SQS Accessment' do
  before(:all) do
    VcrHelper.block_vcr_alert

    survey = SurveyMoonbear::Service::CreateSurvey.new.call(config: CONFIG, current_account: CURRENT_ACCOUNT, title: 'Survey for Responses Testing').value!
    @started_survey = SurveyMoonbear::Service::StartSurvey.new.call(survey_id: survey.id, current_account: CURRENT_ACCOUNT).value!
    @respondent_id = SecureRandom.uuid
  end

  after(:all) do
    SurveyMoonbear::Service::DeleteSurvey.new.call(config: CONFIG, survey_id: @started_survey.id)

    DatabaseHelper.wipe_database
    VcrHelper.unblock_vcr_alert
  end

  describe 'HAPPY: should be able to send & poll responses from SQS' do
    i_suck_and_my_tests_are_order_dependent!

    it 'HAPPY: should be able to send responses to SQS' do
      response_params = {"moonbear_start_time"=>"Wed Mar 27 2019 09:38:06 GMT+0800 (台北標準時間)", "moonbear_end_time"=>"Wed Mar 27 2019 09:38:52 GMT+0800 (台北標準時間)", "name"=>"myName", "self_intro"=>"This is my self introduction", "checkbox_social_website"=>"LINE", "social_website"=>"Facebook, Instagram, LINE", "moonbear_url_params"=>"{}"}
      stored_responses_res = SurveyMoonbear::Service::StoreResponses.new.call(survey_id: @started_survey.id,
                                                                              launch_id: @started_survey.launch_id,
                                                                              respondent_id: @respondent_id,
                                                                              responses: response_params,
                                                                              config: CONFIG)
      _(stored_responses_res.success?).must_equal true
      _(stored_responses_res.value!).must_be_nil
    end

    it 'HAPPY: should be able to poll correct queue msg' do
      q = SurveyMoonbear::Messaging::Queue.new(CONFIG.RES_QUEUE_URL, CONFIG)
      q.poll do |msg|
        response_hashes = JSON.parse(msg)

        _(response_hashes).must_be_instance_of Array
        _(response_hashes[0]['respondent_id']).wont_be_nil
      end
    end
  end
end
