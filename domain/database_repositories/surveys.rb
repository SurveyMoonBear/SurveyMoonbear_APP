module SurveyMoonbear
  module Repository
    # Repository for Account Entities
    class Surveys
      def self.find_origin_id(origin_id)
        db_record = Database::SurveyOrm.first(origin_id: origin_id)
        rebuild_entity(db_record)
      end

      def self.find_id(id)
        db_record = Database::SurveyOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_owner(owner_id)
        db_records = Database::SurveyOrm.where(owner_id: owner_id).all

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

        db_survey = Database::SurveyOrm.create(
          owner: db_owner,
          origin_id: entity.origin_id,
          title: entity.title
        )

        rebuild_entity(db_survey)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Survey.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          origin_id: db_record.origin_id,
          title: db_record.title
        )
      end
    end
  end
end
