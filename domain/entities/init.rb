# frozen_string_literal: false

require 'dry-types'

module SurveyMoonbear
  module Entity
    # Add dry types to Entity module
    module Types
      include Dry::Types.module
    end
  end
end

# Dir.glob("#{File.dirname(__FILE__)}/*.rb").each do |file|
#   require file
# end

require_relative 'account.rb'
require_relative 'survey.rb'
require_relative 'page.rb'
require_relative 'item.rb'
require_relative 'response.rb'
