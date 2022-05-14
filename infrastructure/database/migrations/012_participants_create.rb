# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:participants) do
      uuid :id, primary_key: true
      foreign_key :owner_id, :accounts
      foreign_key :study_id, :studies, type: :uuid

      String      :details
      String      :nickname, null: false
      String      :contact_type, null: false
      String      :email, null: false
      String      :phone
      String      :aws_arn
      String      :noti_status, default: 'checking'
      String      :act_status, default: 'checking'

      DateTime :created_at
      DateTime :updated_at

      unique %I[owner_id study_id nickname email]
    end
  end
end
