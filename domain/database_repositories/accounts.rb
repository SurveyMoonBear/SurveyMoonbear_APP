module SurveyMoonbear
  module Repository
    # Repository for Account Entities
    class Accounts
      def self.find_email(email)
        db_record = Database::AccountOrm.first(email: email)
        rebuild_entity(db_record)
      end

      def self.find_id(id)
        db_record = Database::AccountOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find_email(entity.email) || create_from(entity)
      end

      def self.create_from(entity)
        db_account = Database::AccountOrm.create(
          email: entity.email,
          username: entity.username,
          access_token: entity.access_token
        )

        rebuild_entity(db_account)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Account.new(
          id: nil,
          email: db_record.email,
          username: db_record.username,
          access_token: db_record.access_token
        )
      end
    end
  end
end
