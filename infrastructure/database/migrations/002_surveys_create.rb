require 'sequel'

Sequel.migration do
  change do
    create_table(:surveys) do
      primary_key :id
      foreign_key :owner_id, :accounts
      String      :origin_id, unique: true
      String      :title
    end
  end
end
