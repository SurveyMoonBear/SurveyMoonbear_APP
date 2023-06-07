# frozen_string_literal: true

folders = %w[auth outputs responses retrieve_surveys surveys text_report learning_analytics visual_report studies participants notifications events]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
