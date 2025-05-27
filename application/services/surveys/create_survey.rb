# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::CreateSurvey.new.call(config: <config>, current_account: {...}, title: "...", study_id: "...")
    class CreateSurvey
      include Dry::Transaction
      include Dry::Monads

      step :refresh_access_token
      step :copy_sample_spreadsheet
      step :store_belongs_study
      step :link_owner_to_survey

      private

      # input { config:, current_account:, title: }
      def refresh_access_token(input)
        input[:current_account]['access_token'] = Google::Auth.new(input[:config]).refresh_access_token

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      # input { config:, current_account:, title:, study_id: }
      def copy_sample_spreadsheet(input)
        new_survey = CopySurvey.new.call(config: input[:config],
                                         current_account: input[:current_account],
                                         spreadsheet_id: input[:config].SAMPLE_FILE_ID,
                                         title: input[:title])
        if new_survey.success?
          input[:survey] = new_survey.value!
          Success(input)
        else
          Failure(new_survey.failure)
        end
      end

      # input { ..., survey: }
      def store_belongs_study(input)
        unless input[:study_id].nil?
          Repository::For[Entity::Study].add_survey(input[:study_id], input[:survey].id)
        end
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to add related study in to survey.')
      end

      
      def link_owner_to_survey(input)
        account_survey = Entity::AccountSurvey.new(
          owner_id: input[:current_account]['id'],
          survey_id: input[:survey].id,
          role: 'owner',
          created_at: Time.now,
          updated_at: Time.now
        )

        Repository::For[Entity::AccountSurvey].create(account_survey)
        Success(input[:survey])
      rescue StandardError => e
        puts e
        Failure('Failed to associate owner account with survey.')
      end
    end
  end
end