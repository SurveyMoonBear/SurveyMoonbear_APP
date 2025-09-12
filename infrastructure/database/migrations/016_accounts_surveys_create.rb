# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:accounts_surveys) do
      primary_key [:codesigner_id, :survey_id]
      foreign_key :codesigner_id, :accounts
      foreign_key :survey_id, :surveys, type: :uuid

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
