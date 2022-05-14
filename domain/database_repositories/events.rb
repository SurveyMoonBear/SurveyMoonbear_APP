# frozen_string_literal: true

module SurveyMoonbear
  module Repository
    # Repository for Event Entities
    class Events
      def self.find_id(id)
        db_record = Database::EventOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_owner(owner_id)
        db_records = Database::EventOrm.where(owner_id: owner_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_participant(participant_id)
        db_records = Database::EventOrm.where(participant_id: participant_id).all

        return nil if db_records.nil?

        db_records.map do |db_record|
          rebuild_entity(db_record)
        end
      end

      def self.find_or_create(entity)
        find_id(entity.id) || create_from(entity)
      end

      def self.create_from(entity)
        new_owner = Accounts.find_or_create(entity.owner)
        db_owner = Database::AccountOrm.first(id: new_owner.id)
        new_participant = Participants.find_or_create(entity.participant)
        db_participant = Database::ParticipantOrm.first(id: new_participant.id)

        db_event = Database::EventOrm.create(
          owner: db_owner,
          participant: db_participant,
          start_at: entity.start_at,
          end_at: entity.end_at
          # time_zone: entity.time_zone
        )

        rebuild_entity(db_event)
      end

      def self.update(id, params)
        db_event = Database::EventOrm.where(id: id).first
        db_event.update(params)

        rebuild_entity(db_event)
      end

      def self.delete_all(db_records)
        db_records.map do |record|
          delete_from(record.id)
        end
      end

      def self.delete_from(id)
        db_event = Database::EventOrm.where(id: id).first

        db_event.destroy
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Event.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          participant: Participants.rebuild_entity(db_record.participant),
          start_at: db_record.start_at,
          end_at: db_record.end_at,
          # time_zone: db_record.time_zone,
          created_at: db_record.created_at,
          updated_at: db_record.updated_at
        )
      end
    end
  end
end
