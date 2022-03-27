require 'sequel'

Sequel.migration do
  change do
    alter_table(:items) do
      add_column :flow_logic, String, null: true
    end
  end
end
