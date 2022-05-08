# frozen_string_literal: true

module SurveyMoonbear
  module Repository
    # Repository for Participant Entities
    class Participants
      def self.find_id(id)
        db_record = Database::ParticipantOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_owner(owner_id)
        db_records = Database::ParticipantOrm.where(owner_id: owner_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_study(study_id)
        db_records = Database::ParticipantOrm.where(study_id: study_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_title(title)
        db_record = Database::ParticipantOrm.first(title: title)
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

        db_participant = Database::ParticipantOrm.create(
          owner: db_owner,
          study: db_study,
          details: entity.details,
          nickname: entity.nickname,
          contact_type: entity.contact_type,
          email: entity.email,
          phone: entity.phone,
          aws_arn: entity.aws_arn,
          status: entity.status
        )

        rebuild_entity(db_participant)
      end

      def self.update_state(entity)
        db_participant = Database::ParticipantOrm.find(id: entity.id)

        db_participant.update(state: 'closed')

        rebuild_entity(db_participant)
      end

      def self.update(id, params)
        db_participant = Database::ParticipantOrm.where(id: id).first
        db_participant.update(params)

        rebuild_entity(db_participant)
      end

      def self.update_arn(id, aws_arn)
        db_participant = Database::ParticipantOrm.where(id: id).first
        db_participant.update(aws_arn: aws_arn)

        rebuild_entity(db_participant)
      end

      def self.delete_from(id)
        db_participant = Database::ParticipantOrm.where(id: id).first

        # db_participant.destroy => delete related entity
        db_participant.delete
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Participant.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          study: Studies.rebuild_entity(db_record.study),
          details: db_record.details,
          nickname: db_record.nickname,
          contact_type: db_record.contact_type,
          email: db_record.email,
          phone: db_record.phone,
          aws_arn: db_record.aws_arn,
          status: db_record.status,
          created_at: db_record.created_at
        )
      end
    end
  end
end
