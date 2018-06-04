module SurveyMoonbear
  module Repository
    class Responses
      def self.find_id(id)
        db_record = Database::ResponseOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find_id(entity.id) || create_from(entity)
      end

      def self.create_from(entity)
        db_response = Database::ResponseOrm.create(
          respondent_id: entity.respondent_id,
          page_id: entity.page_id,
          item_id: entity.item_id,
          response: entity.response,
          item_type: entity.item_type,
          item_name: entity.item_name,
          item_description: entity.item_description,
          item_required: entity.item_required,
          item_options: entity.item_options
        )

        rebuild_entity(db_response)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Response.new(
          id: db_record.id,
          respondent_id: db_record.respondent_id,
          page_id: db_record.page_id,
          item_id: db_record.item_id,
          response: db_record.response,
          item_type: db_record.item_type,
          item_name: db_record.item_name,
          item_description: db_record.item_description,
          item_required: db_record.item_required,
          item_options: db_record.item_options
        )
      end
    end
  end
end
