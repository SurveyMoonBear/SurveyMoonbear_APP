# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:pages) do
      primary_key :id
      foreign_key :survey_id, :surveys
      Integer     :index
      String      :title
    end
  end
end
