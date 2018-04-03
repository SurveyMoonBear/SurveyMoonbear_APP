require 'sequel'

Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id
      String      :email, unique: true
      String      :username
      String      :access_token
    end
  end
end
