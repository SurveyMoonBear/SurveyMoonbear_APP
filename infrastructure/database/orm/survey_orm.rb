# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class SurveyOrm < Sequel::Model(:surveys)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'

      one_to_many :pages,
                  class: :'SurveyMoonbear::Database::PageOrm',
                  key: :survey_id

      one_to_many :responses,
                  class: :'SurveyMoonbear::Database::ResponseOrm',
                  key: :survey_id

      # many_to_many :contributors,
      #              class: :'CodePraise::Database::CollaboratorOrm',
      #              join_table: :repos_contributors,
      #              left_key: :repo_id, right_key: :collaborator_id
      # plugin :timestamps, update_on_create: true
    end
  end
end
