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

      def self.find_title(title)
        db_record = Database::SurveyOrm.first(title: title)
        rebuild_entity(db_record)
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

        entity.pages.each do |page|
          stored_page = Pages.find_or_create(page)
          page = Database::PageOrm.first(id: stored_page.id)
          db_survey.add_page(page)
        end

        rebuild_entity(db_survey)
      end

      def self.add_launch(entity)
        db_survey = Database::SurveyOrm.where(origin_id: entity.origin_id).first
        new_launch = Launches.create
        db_launch = Database::LaunchOrm.first(id: new_launch.id)

        # delete old records
        db_survey.pages.each do |page|
          page.items_dataset.destroy
          page.delete
        end

        db_survey = Database::SurveyOrm.where(origin_id: entity.origin_id).first
        db_survey.update(state: 'started')
        db_survey.update(launch_id: db_launch.id)

        # add new records
        entity.pages.each do |page|
          stored_page = Pages.find_or_create(page)
          page = Database::PageOrm.first(id: stored_page.id)
          db_survey.add_page(page)
        end

        db_survey.add_launch(db_launch)

        rebuild_entity(db_survey)
      end

      def self.update_state(entity)
        db_survey = Database::SurveyOrm.find(id: entity.id)

        db_survey.update(state: 'closed')

        rebuild_entity(db_survey)
      end

      def self.update_options(entity, option_name, new_option_value)
        db_survey = Database::SurveyOrm.find(id: entity.id)
        options = JSON.parse(db_survey.options)
        options[option_name] = new_option_value

        db_survey.update(options: options.to_json)

        rebuild_entity(db_survey)
      end

      def self.update_title(entity)
        db_survey = Database::SurveyOrm.where(origin_id: entity.origin_id).first
        db_survey.update(title: entity.title)

        rebuild_entity(db_survey)
      end

      def self.delete_from(id)
        db_survey = Database::SurveyOrm.where(id: id).first
        db_survey.pages.each do |page|
          page.items.each(&:delete)
          page.delete
        end

        db_survey.launches.each do |launch|
          launch.responses.each(&:delete)
          launch.delete
        end

        db_survey.delete
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        pages = db_record.pages.map do |db_page|
          Pages.rebuild_entity(db_page)
        end

        launches = db_record.launches.map do |db_launch|
          Launches.rebuild_entity(db_launch)
        end

        Entity::Survey.new(
          id: db_record.id,
          owner: Accounts.rebuild_entity(db_record.owner),
          launch_id: db_record.launch_id,
          origin_id: db_record.origin_id,
          title: db_record.title,
          created_at: db_record.created_at,
          state: db_record.state,
          options: db_record.options,
          pages: pages,
          launches: launches
        )
      end
    end
  end
end
