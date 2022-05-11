# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:events) do
      primary_key :id
      foreign_key :owner_id, :accounts
      foreign_key :participant_id, :participants, type: :uuid

      String      :origin_id
      DateTime    :start_at
      DateTime    :end_at
      String      :time_zone

      DateTime :created_at
      DateTime :updated_at

      unique %I[owner_id participant_id origin_id]
    end
  end
end
