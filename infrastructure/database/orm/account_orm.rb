# frozen_string_literal: true

module SurveyMoonbear
  module Database
    # Object Relational Mapper for Repo Entities
    class AccountOrm < Sequel::Model(:accounts)
      one_to_many :owned_surveys,
                  class: :'SurveyMoonbear::Database::SurveyOrm',
                  key: :owner_id

      def access_token=(acctoken_plain)
        self.access_token_secure = SecureDB.encrypt(acctoken_plain)
      end

      def access_token
        SecureDB.decrypt(access_token_secure)
      end

      def refresh_token=(reftoken_plain)
        self.refresh_token_secure = SecureDB.encrypt(reftoken_plain)
      end

      def refresh_token
        SecureDB.decrypt(refresh_token_secure)
      end
    end
  end
end
