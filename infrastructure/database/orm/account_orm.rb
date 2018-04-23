module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class AccountOrm < Sequel::Model(:accounts)
      one_to_many :owned_surveys,
                  class: :'SurveyMoonbear::Database::SurveyOrm',
                  key: :owner_id

      # many_to_many :contributors,
      #              class: :'CodePraise::Database::CollaboratorOrm',
      #              join_table: :repos_contributors,
      #              left_key: :repo_id, right_key: :collaborator_id
      # plugin :timestamps, update_on_create: true
      def access_token=(acctoken_plain)
        self.access_token_secure = SecureDB.encrypt(acctoken_plain)
        puts 'access token is encrypted'
      end

      def access_token
        SecureDB.decrypt(access_token_secure)
      end
    end
  end
end
