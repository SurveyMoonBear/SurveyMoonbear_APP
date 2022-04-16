# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Returns a new survey, or nil
    # Usage: Service::CreateVisualReport.new.call(config: <config>, current_account: {...}, title: "...", sources:)
    class CreateVisualReport
      include Dry::Transaction
      include Dry::Monads

      step :refresh_access_token
      step :copy_sample_spreadsheet
      step :read_source_spreadsheet
      step :get_source_type
      # step :source_name_data_validation
      # step :question_data_validation

      private

      # input { config:, current_account:, title: }
      def refresh_access_token(input)
        input[:current_account]['access_token'] = Google::Auth.new(input[:config]).refresh_access_token

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to refresh GoogleSpreadsheetAPI access token.')
      end

      # input { config:, current_account:, title: }
      def copy_sample_spreadsheet(input)
        new_survey = CopyVisualReport.new.call(access_token: input[:current_account]['access_token'],
                                               current_account: input[:current_account],
                                               spreadsheet_id: input[:config].VIZ_SAMPLE_FILE_ID,
                                               title: input[:title])
        if new_survey.success?
          input[:new_sheet] = new_survey
          Success(input)
        else
          Failure('Failed to copy sample spreadsheet.')
        end
      end

      # input { config:, current_account:, title:, new_sheet}
      def read_source_spreadsheet(input)
        input[:sheets_api] = Google::Api::Sheets.new(input[:current_account]['access_token'])
        input[:sources_sheet] = input[:sheets_api].items_data(input[:new_sheet].value!.origin_id,
                                                              'sources') # sources = sheet's title
        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to read sources spreadsheet.')
      end

      def get_source_type(input)
        sheet_id = input[:sheets_api].survey_data(input[:new_sheet].value!.origin_id)['sheets'][0]['properties']['sheetId']
        items_data = input[:sources_sheet]['values'].reject(&:empty?) # Remove empty rows
        items_data.shift
        items_data.each_with_index do |item_data, row_idx|
          row_dict = {}
          if item_data[0] == 'surveymoonbear'
            input[:surveys] = Repository::For[Entity::Survey].find_owner(input[:current_account]['id'])
            if !input[:surveys].nil?
              source_name = []
              input[:surveys].each do |survey|
                source_name.append(survey.title)
              end
              row_dict['start'] = row_idx + 1
              row_dict['end'] = row_idx + 2
              binding.irb
              input[:sheets_api].set_data_validation(input[:new_sheet].value!.origin_id, sheet_id, source_name, row_dict)
            end
          end
        end

        Success(input[:new_sheet].value!)
      rescue StandardError => e
        puts e
        Failure('Failed to get moonbear surveys or set sources data validation.')
      end

      # def source_name_data_validation(input)
      #   if !input[:surveys].nil?
      #     source_name = []
      #     input[:surveys].each do |survey|
      #       source_name.append(survey.title)
      #     end
      #     sheet_id = input[:sheets_api].survey_data(input[:new_sheet].value!.origin_id)['sheets'][0]['properties']['sheetId']
      #     input[:sheets_api].set_data_validation(input[:new_sheet].value!.origin_id, sheet_id, source_name)
      #   end

      #   Success(input[:new_sheet].value!)
      # rescue StandardError => e
      #   puts e
      #   Failure('Failed to set sources data validation.')
      # end

      # TODO questions data validation
      # def question_data_validation(input)

      #   Success(input[:new_sheet].value!)
      # rescue StandardError => e
      #   puts e
      #   Failure('Failed to set questions data validation.')
      # end
    end
  end
end
