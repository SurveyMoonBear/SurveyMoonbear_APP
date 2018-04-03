# frozen_string_literal: true

require 'sequel'

Dir.glob("#{File.dirname(__FILE__)}/*_orm.rb").each do |file|
  require file
end

require_relative 'orm.rb'
