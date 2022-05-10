# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:studies_surveys) do
      primary_key [:study_id, :survey_id]
      foreign_key :study_id, :studies, type: :uuid
      foreign_key :survey_id, :surveys, type: :uuid

      index [:study_id, :survey_id]
    end
  end
end
