# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:studies) do
      uuid :id, primary_key: true
      foreign_key :owner_id, :accounts

      String      :title, null: false
      String      :desc
      String      :state, default: 'closed'
      Bool        :enable_notification, default: false
      String      :aws_arn
      Bool        :track_activity, default: false
      DateTime    :activity_start_at
      DateTime    :activity_end_at

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
