module SurveyMoonbear
  module Repository
    class Launches
      def self.find_id(id)
        db_record = Database::LaunchOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find_id(entity.id) || create
      end

      def self.create
        db_launch = Database::LaunchOrm.create

        rebuild_entity(db_launch)
      end

      def self.update_state(entity)
        db_launch = Database::LaunchOrm.where(id: entity.id).first
        db_launch.update(closed_at: Time.now, state: 'closed')

        rebuild_entity(db_launch)
      end

      def self.add_responses(launch_id, response_entities)
        db_launch = Database::LaunchOrm.where(id: launch_id).first
        response_entities.each do |response_entity|
          db_launch.add_response(response_entity.to_h)
        end
      end

      def self.add_multi_responses(launch_id, response_entities)
        responses_hash = response_entities.map do |response_entity|
          response_hash = response_entity.to_h
          response_hash[:launch_id] = launch_id
          response_hash
        end
        App.DB[:responses].multi_insert(responses_hash)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        responses = db_record.responses.map do |db_response|
          Responses.rebuild_entity(db_response)
        end

        Entity::Launch.new(
          id: db_record.id,
          started_at: db_record.started_at,
          closed_at: db_record.closed_at,
          state: db_record.state,
          responses: responses
        )
      end
    end
  end
end
