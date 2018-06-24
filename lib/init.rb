# frozen_string_literal: false

Dir.glob("#{File.dirname(__FILE__)}/*.rb").each do |file|
  require file
end
