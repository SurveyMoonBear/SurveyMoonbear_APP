# frozen_string_literal: true

folders = %w[auth outputs responses retrieve_surveys surveys visual_report studies participants notifications]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
