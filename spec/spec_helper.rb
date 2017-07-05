require 'rubygems'
require 'rspec'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f}
require File.dirname(__FILE__) + '/../lib/turbot_runner'

RSpec.configure do |c|
  c.include(Helpers)
end
