# frozen_string_literal: false

folders = %w[controllers services]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
