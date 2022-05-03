module SurveyMoonbear
  module Repository
    # Repository for Account Entities
    class VisualReports
      def self.find_origin_id(origin_id)
        db_record = Database::VisualReportOrm.first(origin_id: origin_id)
        rebuild_entity(db_record)
      end

      def self.find_id(id)
        db_record = Database::VisualReportOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_owner(owner_id)
        db_records = Database::VisualReportOrm.where(owner_id: owner_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_or_create(entity)
        find_origin_id(entity.origin_id) || create_from(entity)
      end

      def self.create_from(entity)
        new_owner = Accounts.find_or_create(entity.owner)
        db_owner = Database::AccountOrm.first(id: new_owner.id)

        db_report = Database::VisualReportOrm.create(
          owner: db_owner,
          origin_id: entity.origin_id,
          title: entity.title
        )

        rebuild_entity(db_report)
      end

      def self.update_title(entity)
        db_report = Database::VisualReportOrm.where(origin_id: entity.origin_id).first
        db_report.update(title: entity.title)

        rebuild_entity(db_report)
      end

      def self.delete_from(id)
        db_report = Database::VisualReportOrm.where(id: id).first
        db_report.delete
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::VisualReport.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          origin_id: db_record.origin_id,
          title: db_record.title,
          created_at: db_record.created_at
        )
      end
    end
  end
end
