# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id
      String      :email, unique: true
      String      :username
      String      :access_token_secure, text: true
    end
  end
end
