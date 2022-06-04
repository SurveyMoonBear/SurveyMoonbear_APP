# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Usage: Service::UpdateVisualReport.new.call(redis: "...", visual_report_id: "...", spreadsheet_id: "...", config: <config>, acess_token)
    class UpdateVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :wipe_visual_report_cache
      step :get_visual_report_owner_name
      step :delete_keys_in_redis
      step :transform_responses

      private

      # input { cache_key:, redis:, visual_report_id:, spreadsheet_id:... }
      def wipe_visual_report_cache(input)
        if App.environment == :production
          metastore_uri = input[:config].REDIS_URL + input[:config].REDIS_RACK_CACHE_METASTORE
          entitystore_uri = input[:config].REDIS_URL + input[:config].REDIS_RACK_CACHE_ENTITYTORE
          metastore = Rack::Cache::Storage.instance.resolve_metastore_uri(metastore_uri)
          entitystore = Rack::Cache::Storage.instance.resolve_entitystore_uri(entitystore_uri)
          stored_meta = metastore.read(input[:cache_key])
          entitystore.purge(stored_meta[0][1]["X-Content-Digest"])
          metastore.purge(input[:cache_key])
        end

        Success(input)
      rescue StandardError
        Failure('Failed to wipe visual report cache.')
      end

      # input { redis:, visual_report_id:, spreadsheet_id:... }
      def get_visual_report_owner_name(input)
        input[:visual_report] = Repository::For[Entity::VisualReport].find_id(input[:visual_report_id])
        input[:user_key] = input[:visual_report].owner.username + input[:spreadsheet_id]

        Success(input)
      rescue StandardError
        Failure('Failed to get visual report owner from db.')
      end

      # input { redis:, user_key:, ... }
      def delete_keys_in_redis(input)
        sources = input[:redis].get(input[:user_key])['source']
        sources.each do |source|
          if source[0] == 'spreadsheet'
            url = source[1] # https://docs.google.com/spreadsheets/d/<spreadsheet_id>/edit#gid=789293273
            other_sheet_id = url.match('.*/(.*)/')[1]
            input[:redis].delete("other_sheet#{other_sheet_id}")
          end
        end
        input[:redis].delete(input[:user_key])
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to delete source in redis.')
      end

      # input { redis:, visual_report:, spreadsheet_id:, access_token:, config:, user_key: }
      def transform_responses(input)
        responses = TransformVisualSheetsToChart.new.call(user_key: input[:user_key],
                                                          visual_report: input[:visual_report],
                                                          spreadsheet_id: input[:spreadsheet_id],
                                                          config: input[:config],
                                                          redis: input[:redis],
                                                          access_token: input[:access_token])
        if responses.success?
          input[:all_graphs] = responses.value!
          Success(input)
        else
          Failure(responses.failure)
        end
      end
    end
  end
end
