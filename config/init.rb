# frozen_string_literal: false

# require_relative 'environment.rb'
Dir.glob("#{File.dirname(__FILE__)}/**/*.rb").each do |file|
  require file
end
