# frozen_string_literal: false

folders = %w[database/orm]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
