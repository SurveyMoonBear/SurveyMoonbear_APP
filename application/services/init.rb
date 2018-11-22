# frozen_string_literal: true

folders = %w[auth outputs responses retrieve_surveys surveys]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
