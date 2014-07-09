require 'json'
require 'turbot_runner'

describe TurbotRunner::BaseRunner do
  it 'can run a bot' do

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

    expect(runner).to receive(:handle_valid_record).with({'n' => 1, 'hello' => 'hello, 1'}, 'hello')
    expect(runner).to receive(:handle_valid_record).with({'n' => 1, 'goodbye' => 'goodbye, 1'}, 'goodbye')
    expect(runner).to receive(:handle_valid_record).with({'n' => 2, 'hello' => 'hello, 2'}, 'hello')
    expect(runner).to receive(:handle_valid_record).with({'n' => 2, 'goodbye' => 'goodbye, 2'}, 'goodbye')
    expect(runner).to receive(:handle_invalid_record).with({'n' => 3}, 'hello', [:error])
    expect(runner).to receive(:handle_valid_record).with({'n' => 4, 'hello' => 'hello, 4'}, 'hello')
    expect(runner).to receive(:handle_valid_record).with({'n' => 4, 'goodbye' => 'goodbye, 4'}, 'goodbye')
    expect(runner).to receive(:handle_successful_run)
    runner.run
  end
end
