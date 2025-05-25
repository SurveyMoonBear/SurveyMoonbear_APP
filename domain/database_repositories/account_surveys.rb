module SurveyMoonbear
  module Repository
    # Repository for AccountSurveys Entities
    class AccountSurveys
      def self.create(entity)
        db_record = Database::AccountSurveysOrm.create(
          owner_id: entity.owner_id,
          survey_id: entity.survey_id,
          role: entity.role,
          created_at: entity.created_at,
          updated_at: entity.updated_at
        )
        rebuild_entity(db_record)
      end

      def self.find(owner_id:, survey_id:)
        db_record = Database::AccountSurveysOrm.first(
          owner_id: owner_id,
          survey_id: survey_id
        )
        rebuild_entity(db_record)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::AccountSurvey.new(
          owner_id: db_record.owner_id,
          survey_id: db_record.survey_id,
          role: db_record.role,
          created_at: db_record.created_at,
          updated_at: db_record.updated_at
        )
      end
    end
  end
end
