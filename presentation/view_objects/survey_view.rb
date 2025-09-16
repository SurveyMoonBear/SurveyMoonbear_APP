# frozen_string_literal: true

# module SurveyMoonbear
module Views
  # View for a survey hash
  class SurveyView
    def initialize(survey:, role:, policy:, designers_info: nil)
      @survey = survey
      @role = role
      @policy = policy
      @designers_info = designers_info
    end


    def id
      @survey.id
    end

    def title
      @survey.title
    end

    def created_at
        format_time(@survey.created_at)
    end

    def origin_id
      @survey.origin_id
    end

    def state
      @survey.state
    end

    def role
      @role
    end
    
    def designers_info
      @designers_info
    end

    # authority
    def can_delete?
      @policy[:can_delete]
    end

    def can_view?
      @policy[:can_view]
    end

    def can_add_codesigners?
       @policy[:can_add_codesigners]
    end

    def can_remove_codesigner?
        @policy[:can_remove_codesigner]
    end
    

    # URL
    def preview_url
      "/survey/#{id}/preview/#{origin_id}"
    end

    def spreadsheet_url
      "https://docs.google.com/spreadsheets/d/#{origin_id}/edit"
    end

    def launch_url
      return nil unless @survey.launch_id

      "#{config.APP_URL}/onlinesurvey/#{id}/#{@survey.launch_id}"
    end

    # 可選：支援原始 hash 存取
    def [](key)
        @survey.respond_to?(key) ? @survey.public_send(key) : nil
    end

    def to_h
      {
        id: id,
        title: title,
        created_at: created_at,
        origin_id: origin_id,
        state: state,
        role: role,
        can_delete: can_delete?,
        can_view: can_view?,
        can_add_codesigners: can_add_codesigners?,
        can_remove_codesigner: can_remove_codesigner?,
        preview_url: preview_url,
        spreadsheet_url: spreadsheet_url,
        launch_url: launch_url,
        designers_info: designers_info
      }
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
