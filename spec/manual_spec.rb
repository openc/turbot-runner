# These specs test behaviour that is most easily exercised or verified by hand.

$:.unshift('lib')
require 'turbot_runner'

puts
puts '-' * 80

puts <<eos
This tests whether stderr is directed to the console.
When the scraper is run, you should see the following two lines in the console:

doing...
done

Press <enter> to run the test.
eos

gets

bot_location = File.join(File.dirname(__FILE__), 'bots/logging-bot')
runner = TurbotRunner::Runner.new(bot_location).run

puts
puts 'Did you see the expected lines? [y]/n'

exit(1) unless ['Y', 'y', ''].include?(gets.chomp)

puts
puts '-' * 80

puts <<eos
This tests whether hitting Ctrl-C interrupts a running scraper correctly.  When
the scraper is run, it will pause after producing five lines of output, and
instruct you to interrupt it.  You will have ten seconds to do so.

Press <enter> to run the test.
eos

gets

bot_location = File.join(File.dirname(__FILE__), 'bots/bot-with-pause')
runner = TurbotRunner::Runner.new(bot_location).run

expected_output = File.readlines('spec/outputs/truncated-scraper.out').map {|line| JSON.parse(line)}
actual_output = File.readlines('spec/bots/bot-with-pause/output/scraper.out').map {|line| JSON.parse(line)}

if expected_output == actual_output
  puts 'Bot produced expected output'
else
  puts 'Bot did not produce expected output'
  exit(1)
end

puts
puts '-' * 80
puts 'All tests passed!'
