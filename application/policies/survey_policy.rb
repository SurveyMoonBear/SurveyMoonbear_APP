# frozen_string_literal: true

module SurveyMoonbear
  # Policy to determine if an account can view a particular survey
  class SurveysPolicy
    def initialize(account, survey, role = nil)
      @account = account
      @survey = survey
      @role = role
    end

    def can_view?
      account_is_owner? || account_is_collaborator?
    end

    def can_delete?
      account_is_owner?
    end

    def can_add_codesigners?
      account_is_owner?
    end

    def can_remove_codesigner?
      account_is_owner?
    end

    def can_codesigner?
      not(account_is_owner? or account_is_codesigner?)
    end

    def summary
      {
        can_view: can_view?,
        can_delete: can_delete?,
        can_add_codesigners: can_add_codesigners?,
        can_remove_codesigner: can_remove_codesigner?,
      }
    end

    private

    def account_is_owner?
      @role ? @role == 'owner' : (@survey.owner.id == @account.id)
    end

    def account_is_codesigner?
      @role ? @role == 'codesigner' : false

    end
  end
end