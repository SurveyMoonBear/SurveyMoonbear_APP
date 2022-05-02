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
        find_origin_id(entity.origin_id) || create_from(entity)
      end

      def self.create_from(entity)
        new_owner = Accounts.find_or_create(entity.owner)
        db_owner = Database::AccountOrm.first(id: new_owner.id)

        db_study = Database::StudyOrm.create(
          owner: db_owner,
          origin_id: entity.origin_id,
          title: entity.title
        )

        rebuild_entity(db_study)
      end

      # def self.add_launch(entity)
      #   db_study = Database::StudyOrm.where(origin_id: entity.origin_id).first
      #   new_launch = Launches.create
      #   db_launch = Database::LaunchOrm.first(id: new_launch.id)

      #   db_study = Database::StudyOrm.where(origin_id: entity.origin_id).first
      #   db_study.update(state: 'started')
      #   db_study.update(launch_id: db_launch.id)

      #   db_study.add_launch(db_launch)

      #   rebuild_entity(db_study)
      # end

      def self.update_state(entity)
        db_study = Database::StudyOrm.find(id: entity.id)

        db_study.update(state: 'closed')

        rebuild_entity(db_study)
      end

      def self.update_options(entity, option_name, new_option_value)
        db_study = Database::StudyOrm.find(id: entity.id)
        options = JSON.parse(db_study.options)
        options[option_name] = new_option_value

        db_study.update(options: options.to_json)

        rebuild_entity(db_study)
      end

      def self.update_title(entity)
        db_study = Database::StudyOrm.where(origin_id: entity.origin_id).first
        db_study.update(title: entity.title)

        rebuild_entity(db_study)
      end

      def self.delete_from(id)
        db_study = Database::StudyOrm.where(id: id).first

        # db_study.launches.each do |launch|
        #   launch.responses.each(&:delete)
        #   launch.delete
        # end

        db_study.delete
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        # launches = db_record.launches.map do |db_launch|
        #   Launches.rebuild_entity(db_launch)
        # end

        Entity::Study.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          # launch_id: db_record.launch_id,
          title: db_record.title,
          desc: db_record.desc,
          state: db_record.state,
          aws_arn: db_record.aws_arn,
          track_activity: db_record.track_activity,
          activity_start_at: db_record.activity_start_at,
          activity_end_at: db_record.activity_end_at,
          created_at: db_record.created_at
        )
      end
    end
  end
end
