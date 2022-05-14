# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:events) do
      primary_key :id
      foreign_key :owner_id, :accounts
      foreign_key :participant_id, :participants, type: :uuid

      DateTime    :start_at
      DateTime    :end_at
      # String      :time_zone

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
