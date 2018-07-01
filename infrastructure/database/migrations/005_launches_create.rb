# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:launches) do
      uuid        :id, primary_key: true
      uuid        :survey_id, foreign_key: true, table: :surveys
      Time        :started_at
      Time        :closed_at
      String      :state, default: 'started'
    end
  end
end
