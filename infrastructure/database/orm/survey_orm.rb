module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class SurveyOrm < Sequel::Model(:surveys)
      many_to_one :owner,
                  class: :'SurveyMoonbear::Database::AccountOrm'

      # many_to_many :contributors,
      #              class: :'CodePraise::Database::CollaboratorOrm',
      #              join_table: :repos_contributors,
      #              left_key: :repo_id, right_key: :collaborator_id
      # plugin :timestamps, update_on_create: true
    end
  end
end
