module SurveyMoonbear
  module Repository
    # Repository for Account Entities
    class Accounts
      def self.find_entity(entity)
        db_record = Database::AccountOrm.first(email: entity.email)
        db_record&.update(username: entity.username,
                          access_token: entity.access_token,
                          refresh_token: entity.refresh_token)
        rebuild_entity(db_record)
      end

      def self.find_id(id)
        db_record = Database::AccountOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find_entity(entity) || create_from(entity)
      end

      def self.create_from(entity)
        db_account = Database::AccountOrm.create(
          email: entity.email,
          username: entity.username,
          access_token: entity.access_token,
          refresh_token: refresh_token
        )

        rebuild_entity(db_account)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Account.new(
          id: db_record.id,
          email: db_record.email,
          username: db_record.username,
          access_token: db_record.access_token,
          refresh_token: db_record.refresh_token
        )
      end
    end
  end
end
