Dir.glob("#{File.dirname(__FILE__)}/*.rb").each do |file|
  require file
end

require_relative 'services_integration/init.rb'