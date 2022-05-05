require 'sequel'

Sequel.migration do
  change do
    alter_table(:accounts) do
      add_column :refresh_token_secure, String, null: true
    end
  end
end
