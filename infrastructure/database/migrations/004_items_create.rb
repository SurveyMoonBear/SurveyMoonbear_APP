# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:items) do
      primary_key :id
      foreign_key :page_id, :pages
      Integer     :order
      String      :type
      String      :name
      String      :description
      Integer     :required
      String      :options, null: true
    end
  end
end
