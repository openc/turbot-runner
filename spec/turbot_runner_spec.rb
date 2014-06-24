require 'json'
require 'turbot_runner'

describe TurbotRunner::BaseRunner do
  it 'can run a bot' do
    # This test runs slowly - there seems to be some delay in subprocesses
    # reading from their stdins, but this is not observed when the code is run
    # outside of rspec.

    class SpecRunner < TurbotRunner::BaseRunner
      def validate(record, data_type)
        if record['n'] == 3
          [:error]
        else
          []
        end
      end
    end

    runner = SpecRunner.new('spec/dummy-bot')

    expect(runner).to receive(:process_valid).with({'n' => 1, 'hello' => 'hello, 1'}, 'hello')
    expect(runner).to receive(:process_valid).with({'n' => 1, 'goodbye' => 'goodbye, 1'}, 'goodbye')
    expect(runner).to receive(:process_valid).with({'n' => 2, 'hello' => 'hello, 2'}, 'hello')
    expect(runner).to receive(:process_valid).with({'n' => 2, 'goodbye' => 'goodbye, 2'}, 'goodbye')
    expect(runner).to receive(:process_invalid).with({'n' => 3}, 'hello')

    expect(runner).to receive(:process_valid).with({'n' => 4, 'hello' => 'hello, 4'}, 'hello')
    expect(runner).to receive(:process_valid).with({'n' => 4, 'goodbye' => 'goodbye, 4'}, 'goodbye')
    runner.run
  end
end
