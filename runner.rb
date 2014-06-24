$: << 'lib'

require 'json'
require 'turbot_runner'

runner = TurbotRunner::Runner.new('spec/dummy-bot')
runner.run do |line|
  puts line
end
