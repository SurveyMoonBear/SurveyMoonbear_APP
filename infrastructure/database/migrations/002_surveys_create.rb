require 'sequel'

Sequel.migration do
  change do
    create_table(:surveys) do
      uuid        :id, primary_key: true
      foreign_key :owner_id, :accounts
      uuid        :launch_id
      String      :origin_id, unique: true
      String      :title
      TrueClass   :start_flag, default: false
    end
  end
end
