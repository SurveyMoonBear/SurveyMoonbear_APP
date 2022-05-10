# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:notifications) do
      primary_key :id
      foreign_key :owner_id, :accounts
      foreign_key :study_id, :studies, type: :uuid
      foreign_key :survey_id, :surveys, type: :uuid

      String      :type, default: 'fixed'
      String      :title, default: 'study_notification', null: false
      DateTime    :fixed_timestamp
      String      :content, default: 'This is a notification message'
      String      :notification_tz # notification's timezone offset (seconds) eg. 32400 (+09:00 -> 9*60*60)
      String      :repeat_at, default: ''
      String      :repeat_set_time
      String      :repeat_random_every # random's time day or week on Mon, Tue... eg. '* * 1,2'
      String      :repeat_random_start
      String      :repeat_random_end

      DateTime :created_at
      DateTime :updated_at

      unique %I[owner_id study_id title]
    end
  end
end
