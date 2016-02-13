module Helpers
  def test_runner(name, opts={})
    test_bot_location = File.join(File.dirname(__FILE__), '../bots', name)
    TurbotRunner::Runner.new(test_bot_location, opts)
  end
end
