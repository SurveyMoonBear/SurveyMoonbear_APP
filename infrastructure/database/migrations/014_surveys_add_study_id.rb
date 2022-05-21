# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    alter_table(:surveys) do
      add_foreign_key :study_id, :studies, type: :uuid, if_not_exists: true
    end
  end
end
