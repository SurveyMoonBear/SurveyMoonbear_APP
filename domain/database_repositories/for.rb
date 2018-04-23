module SurveyMoonbear
  module Repository
    For = {
      Entity::Account => Accounts,
      Entity::Survey  => Surveys
    }.freeze
  end
end
