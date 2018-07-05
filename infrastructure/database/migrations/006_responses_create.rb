# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:responses) do
      primary_key :id
      uuid        :survey_id, foreign_key: true, table: :surveys
      uuid        :launch_id, foreign_key: true, table: :launches
      String      :respondent_id
      Integer     :page_index
      Integer     :item_order
      String      :response, null: true
      String      :item_data
    end
  end
end
