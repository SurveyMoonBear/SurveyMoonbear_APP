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

        entity.pages.each do |page|
          stored_page = Pages.find_or_create(page)
          page = Database::PageOrm.first(id: stored_page.id)
          db_survey.add_page(page)
        end

        rebuild_entity(db_survey)
      end

      def self.update_from(entity, launch_id)
        db_survey = Database::SurveyOrm.where(origin_id: entity.origin_id).first

        # delete old records
        db_survey.pages.each do |page|
          page.items_dataset.destroy
          page.delete
        end

        db_survey = Database::SurveyOrm.where(origin_id: entity.origin_id).first
        db_survey.update(start_flag: 1)
        db_survey.update(launch_id: launch_id)

        # add new records
        entity.pages.each do |page|
          stored_page = Pages.find_or_create(page)
          page = Database::PageOrm.first(id: stored_page.id)
          db_survey.add_page(page)
        end

        rebuild_entity(db_survey)
      end

      def self.add_response(entity, response_entity)
        db_survey = Database::SurveyOrm.where(origin_id: entity.origin_id).first
        stored_response = Responses.find_or_create(response_entity)
        response = Database::ResponseOrm.first(id: stored_response.id)
        db_survey.add_response(response)

        rebuild_entity(db_survey)
      end

      def self.update_start_flag(entity)
        db_survey = Database::SurveyOrm.where(id: entity.id).first

        if db_survey.start_flag
          db_survey.update(start_flag: 0)
        else
          db_survey.update(start_flag: 1)
        end

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

        if db_survey.responses
          db_survey.responses.each(&:delete)
        end
        db_survey.delete
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        pages = db_record.pages.map do |db_page|
          Pages.rebuild_entity(db_page)
        end

        responses = db_record.responses&.map do |db_response|
          Responses.rebuild_entity(db_response)
        end

        Entity::Survey.new(
          id: db_record.id,
          launch_id: db_record.launch_id,
          owner: Accounts.rebuild_entity(db_record.owner),
          origin_id: db_record.origin_id,
          title: db_record.title,
          start_flag: db_record.start_flag,
          pages: pages,
          responses: responses
        )
      end
    end
  end
end
