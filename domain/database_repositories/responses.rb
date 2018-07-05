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
          page_index: entity.page_index,
          item_order: entity.item_order,
          response: entity.response,
          item_data: entity.item_data
        )

        rebuild_entity(db_response)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Response.new(
          id: db_record.id,
          respondent_id: db_record.respondent_id,
          page_index: db_record.page_index,
          item_order: db_record.item_order,
          response: db_record.response,
          item_data: db_record.item_data
        )
      end
    end
  end
end
