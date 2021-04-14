require 'sequel'

Sequel.migration do
  change do
    alter_table(:surveys) do
      add_column :options, String, default: "{\"random\":\"none\"}", if_not_exists: true
    end
  end
end
