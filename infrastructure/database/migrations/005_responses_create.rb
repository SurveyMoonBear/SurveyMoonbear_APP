# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:responses) do
      primary_key :id
      foreign_key :survey_id, :surveys
      String      :respondent_id
      String      :page_id
      String      :item_id
      String      :response, null: true
      String      :item_type
      String      :item_name
      String      :item_description
      Integer     :item_required
      String      :item_options, null: true
    end
  end
end
