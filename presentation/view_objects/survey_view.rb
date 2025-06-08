# frozen_string_literal: true

# module SurveyMoonbear
module Views
  # View for a survey hash
  class SurveyView
    def initialize(survey_hash)
      @survey = survey_hash
    end

    def id
      @survey[:id]
    end

    def title
      @survey[:title]
    end

    def created_at
      format_time(@survey[:created_at])
    end

    def origin_id
      @survey[:origin_id]
    end

    def state
      @survey[:state]
    end

    def role
      @survey[:role]
    end

    # 權限
    def can_delete?
      @survey.dig(:policy, :can_delete)
    end

    def can_view?
      @survey.dig(:policy, :can_view)
    end

    def can_add_collaborators?
      @survey.dig(:policy, :can_add_collaborators)
    end

    def can_remove_collaborators?
      @survey.dig(:policy, :can_remove_collaborators)
    end

    # URL
    def preview_url
      "/survey/#{id}/preview/#{origin_id}"
    end

    def spreadsheet_url
      "https://docs.google.com/spreadsheets/d/#{origin_id}/edit"
    end

    def launch_url
      return nil unless @survey[:launch_id]

      "#{config.APP_URL}/onlinesurvey/#{id}/#{@survey[:launch_id]}"
    end

    # 可選：支援原始 hash 存取
    def [](key)
      @survey[key]
    end

    private

    def format_time(t)
      t.respond_to?(:strftime) ? t.strftime('%Y-%m-%d') : t.to_s
    end

    def config
      Object.const_get(:config)
    end
  end
end
