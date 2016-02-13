require 'rubygems'

unless RUBY_PLATFORM =~ /mswin32|mingw32/
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'rspec'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f}
require File.dirname(__FILE__) + '/../lib/turbot_runner'

RSpec.configure do |c|
  c.include(Helpers)
end
