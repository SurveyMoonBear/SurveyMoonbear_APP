# frozen_string_literal: true

require 'sequel'
require 'base64'

Dir.glob("#{File.dirname(__FILE__)}/*_orm.rb").each do |file|
  require file
end

require_relative 'orm.rb'
