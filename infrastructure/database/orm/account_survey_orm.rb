# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class AccountSurveysOrm < Sequel::Model(:accounts_surveys)
      many_to_one :account,
                  class: :'SurveyMoonbear::Database::AccountOrm',
                  key: :owner_id
      many_to_one :survey,
                  class: :'SurveyMoonbear::Database::SurveyOrm',
                  key: :survey_id
    end
  end
end
