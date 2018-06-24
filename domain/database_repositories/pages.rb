module SurveyMoonbear
  module Repository
    # Repository for Account Entities
    class Pages
      def self.find_id(id)
        db_record = Database::PageOrm.first(id: id)
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
        db_page = Database::PageOrm.create(
          index: entity.index,
          title: entity.title
        )

        entity.items.each do |item|
          stored_item = Items.find_or_create(item)
          item = Database::ItemOrm.first(id: stored_item.id)
          db_page.add_item(item)
        end

        rebuild_entity(db_page)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        items = db_record.items.map do |db_item|
          Items.rebuild_entity(db_item)
        end

        Entity::Page.new(
          id: db_record.id,
          index: db_record.index,
          title: db_record.title,
          items: items
        )
      end
    end
  end
end
