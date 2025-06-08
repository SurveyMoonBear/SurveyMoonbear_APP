require 'dry/monads'
require_relative '../../policies/survey_policy'


module SurveyMoonbear
  module Service
    class ListSurveys
      include Dry::Monads::Result::Mixin

      def call(account_id:)
        account = Repository::Accounts.find_id(account_id)
        survey_infos = Repository::Surveys.find_accessible_with_roles(account_id)
        result = survey_infos.map do |info|
            survey = info[:survey]
            role = info[:role]
            policy = SurveysPolicy.new(account, survey, role)
            Views::SurveyView.new(
              survey.to_h.merge(
                role: role,
                policy: policy.summary
              ))
        end
        Success(result)
      rescue StandardError => e
        puts "LIST SURVEYS ERROR: #{e.message}"
        Failure('Internal error while listing surveys')
      end
    end
  end
end
