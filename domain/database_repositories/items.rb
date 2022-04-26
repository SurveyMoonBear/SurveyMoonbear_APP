module SurveyMoonbear
  module Repository
    # Repository for Account Entities
    class Items
      def self.find_id(id)
        db_record = Database::ItemOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find_id(entity.id) || create_from(entity)
      end

      def self.create_from(entity)
        db_item = Database::ItemOrm.create(
          order: entity.order,
          type: entity.type,
          name: entity.name,
          description: entity.description,
          required: entity.required,
          options: entity.options,
          flow_logic: entity.flow_logic,
          visualization: entity.visualization
        )

        rebuild_entity(db_item)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Item.new(
          id: db_record.id,
          order: db_record.order,
          type: db_record.type,
          name: db_record.name,
          description: db_record.description,
          required: db_record.required,
          options: db_record.options,
          flow_logic: db_record.flow_logic,
          visualization: db_record.visualization
        )
      end
    end
  end
end
