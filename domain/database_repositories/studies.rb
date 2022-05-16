# frozen_string_literal: true

module SurveyMoonbear
  module Repository
    # Repository for Study Entities
    class Studies
      def self.find_id(id)
        db_record = Database::StudyOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_owner(owner_id)
        db_records = Database::StudyOrm.where(owner_id: owner_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_title(title)
        db_record = Database::StudyOrm.first(title: title)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find_id(entity.id) || create_from(entity)
      end

      def self.create_from(entity)
        new_owner = Accounts.find_or_create(entity.owner)
        db_owner = Database::AccountOrm.first(id: new_owner.id)

        db_study = Database::StudyOrm.create(
          owner: db_owner,
          title: entity.title,
          desc: entity.desc,
          enable_notification: entity.enable_notification,
          aws_arn: entity.aws_arn,
          track_activity: entity.track_activity,
          activity_start_at: entity.activity_start_at,
          activity_end_at: entity.activity_end_at
        )

        rebuild_entity(db_study)
      end

      def self.update_state(entity_id, state)
        db_study = Database::StudyOrm.find(id: entity_id)

        db_study.update(state: state)

        rebuild_entity(db_study)
      end

      def self.update_title(id, title)
        db_study = Database::StudyOrm.where(id: id).first
        db_study.update(title: title)

        rebuild_entity(db_study)
      end

      def self.update_arn(id, aws_arn)
        db_study = Database::StudyOrm.where(id: id).first
        db_study.update(aws_arn: aws_arn)

        rebuild_entity(db_study)
      end

      def self.add_survey(id, survey_id)
        db_study = Database::StudyOrm.where(id: id).first
        db_study.add_including_survey(survey_id)
      end

      def self.remove_survey(id, survey_id)
        db_study = Database::StudyOrm.where(id: id).first
        db_study.remove_including_survey(survey_id)
      end

      def self.delete_from(id)
        db_study = Database::StudyOrm.where(id: id).first

        db_study.including_surveys.each do |survey|
          db_study.remove_including_survey(survey.id)
        end

        db_study.destroy
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Study.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          title: db_record.title,
          desc: db_record.desc,
          state: db_record.state,
          enable_notification: db_record.enable_notification,
          aws_arn: db_record.aws_arn,
          track_activity: db_record.track_activity,
          activity_start_at: db_record.activity_start_at,
          activity_end_at: db_record.activity_end_at,
          including_surveys: Surveys.rebuild_many(db_record.including_surveys),
          created_at: db_record.created_at
        )
      end
    end
  end
end
