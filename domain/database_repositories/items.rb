module SurveyMoonbear
  module Repository
    # Repository for Account Entities
    class Items
      def self.find_id(id)
        db_record = Database::ItemOrm.first(id: id)
        rebuild_entity(db_record)
      end

      # def self.find_owner(owner_id)
      #   db_records = Database::SurveyOrm.where(owner_id: owner_id).all

      #   return nil if db_records.nil?

      #   db_records.map do |db_record|
      #     rebuild_entity(db_record)
      #   end
      # end

      def self.find_or_create(entity)
        find_id(entity.id) || create_from(entity)
      end

      def self.create_from(entity)
        # new_owner = Accounts.find_or_create(entity.owner)
        # db_owner = Database::AccountOrm.first(id: new_owner.id)

        db_item = Database::ItemOrm.create(
          type: entity.type,
          name: entity.name,
          description: entity.description,
          required: entity.required,
          options: entity.options
        )

        rebuild_entity(db_item)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Item.new(
          id: db_record.id,
          type: db_record.type,
          name: db_record.name,
          description: db_record.description,
          required: db_record.required,
          options: db_record.options
        )
      end
    end
  end
end
