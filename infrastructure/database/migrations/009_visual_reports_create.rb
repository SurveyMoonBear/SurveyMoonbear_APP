require 'sequel'

Sequel.migration do
  change do
    create_table(:visual_reports) do
      uuid        :id, primary_key: true
      foreign_key :owner_id, :accounts
      String      :origin_id, unique: true
      String      :title
      Time        :created_at

      TrueClass :is_owner, null: false, default: true
    end
  end
end
