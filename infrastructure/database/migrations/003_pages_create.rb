# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:pages) do
      primary_key :id
      uuid        :survey_id, foreign_key: true, table: :surveys
      Integer     :index
      String      :title
    end
  end
end
