# frozen_string_literal: true

folders = %w[lib config infrastructure domain application]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
