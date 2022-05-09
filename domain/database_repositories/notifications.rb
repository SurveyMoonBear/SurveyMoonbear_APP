# frozen_string_literal: true

module SurveyMoonbear
  module Repository
    # Repository for Notification Entities
    class Notifications
      def self.find_id(id)
        db_record = Database::NotificationOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_owner(owner_id)
        db_records = Database::NotificationOrm.where(owner_id: owner_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_study(study_id)
        db_records = Database::NotificationOrm.where(study_id: study_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_title(title)
        db_record = Database::NotificationOrm.first(title: title)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find_id(entity.id) || create_from(entity)
      end

      def self.create_from(entity)
        new_owner = Accounts.find_or_create(entity.owner)
        db_owner = Database::AccountOrm.first(id: new_owner.id)
        new_study = Studies.find_or_create(entity.study)
        db_study = Database::StudyOrm.first(id: new_study.id)
        new_survey = Surveys.find_or_create(entity.survey)
        db_survey = Database::SurveyOrm.first(id: new_survey.id)

        db_notification = Database::NotificationOrm.create(
          owner: db_owner,
          study: db_study,
          survey: db_survey,
          type: entity.type,
          title: entity.title,
          fixed_timestamp: entity.fixed_timestamp,
          content: entity.content,
          notification_tz: entity.notification_tz,
          repeat_at: entity.repeat_at,
          repeat_set_time: entity.repeat_set_time,
          repeat_random_every: entity.repeat_random_every,
          repeat_random_start: entity.repeat_random_start,
          repeat_random_end: entity.repeat_random_end
        )

        rebuild_entity(db_notification)
      end

      def self.update(id, params)
        db_notification = Database::NotificationOrm.where(id: id).first
        db_notification.update(params)

        rebuild_entity(db_notification)
      end

      def self.delete_from(id)
        db_notification = Database::NotificationOrm.where(id: id).first

        db_notification.destroy
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Notification.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          study: Studies.rebuild_entity(db_record.study),
          survey: Surveys.rebuild_entity(db_record.survey),
          type: db_record.type,
          title: db_record.title,
          fixed_timestamp: db_record.fixed_timestamp,
          content: db_record.content,
          notification_tz: db_record.notification_tz,
          repeat_at: db_record.repeat_at,
          repeat_set_time: db_record.repeat_set_time,
          repeat_random_every: db_record.repeat_random_every,
          repeat_random_start: db_record.repeat_random_start,
          repeat_random_end: db_record.repeat_random_end,
          created_at: db_record.created_at
        )
      end
    end
  end
end
