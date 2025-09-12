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
      def self.find_role(account_id, survey_id)

          survey = Repository::Surveys.find_id(survey_id)
          return 'owner' if survey && survey.owner.id == account_id


          db_record = Database::AccountSurveysOrm.first(
            owner_id: account_id,
            survey_id: survey_id
          )
          db_record&.role
      end
      def self.rebuild_entity(db_record)
        return nil unless db_record


      end
    end
  end
end
