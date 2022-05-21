# frozen_string_literal: false

folders = %w[google database/orm messaging cache session]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
