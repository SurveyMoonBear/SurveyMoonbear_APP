require 'sequel'

Sequel.migration do
  change do
    alter_table(:items) do
      add_column :link_to, String, null: true
      add_column :visualization, String, null: true
    end
  end
end
