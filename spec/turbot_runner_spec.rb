require 'json'
require 'turbot_runner'

class SpecRunner < TurbotRunner::BaseRunner
  def validate(record, data_type)
    if record['n'] % 4 == 3
      [:error]
    else
      []
    end
  end
end

class BrokenRunner < TurbotRunner::BaseRunner
  def validate(record, data_type)
    []
  end

  def handle_failed_run
  end
end


describe TurbotRunner::BaseRunner do
  it 'can run a ruby bot' do
    runner = SpecRunner.new('spec/dummy-bot-ruby')

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

  it 'can run a python bot' do
    runner = SpecRunner.new('spec/dummy-bot-python')

    expect(runner).to receive(:handle_valid_record).with({'n' => 5, 'hello' => 'hello, 5'}, 'hello')
    expect(runner).to receive(:handle_valid_record).with({'n' => 5, 'goodbye' => 'goodbye, 5'}, 'goodbye')
    expect(runner).to receive(:handle_valid_record).with({'n' => 6, 'hello' => 'hello, 6'}, 'hello')
    expect(runner).to receive(:handle_valid_record).with({'n' => 6, 'goodbye' => 'goodbye, 6'}, 'goodbye')
    expect(runner).to receive(:handle_invalid_record).with({'n' => 7}, 'hello', [:error])
    expect(runner).to receive(:handle_valid_record).with({'n' => 8, 'hello' => 'hello, 8'}, 'hello')
    expect(runner).to receive(:handle_valid_record).with({'n' => 8, 'goodbye' => 'goodbye, 8'}, 'goodbye')
    expect(runner).to receive(:handle_successful_run)
    runner.run
  end

  describe "broken bots" do
    describe "failing bot without transformer" do
      it 'should call handle_failed_run' do
        runner = BrokenRunner.new('spec/dummy-broken-bot-ruby')
        expect(runner).to receive(:handle_valid_record)
        expect(runner).to receive(:handle_failed_run)
        runner.run
      end
    end

    describe "failing bot with transformer" do
      it 'should call handle_failed_run' do
        runner = BrokenRunner.new('spec/dummy-broken-bot-ruby-2')
        expect(runner).to receive(:handle_valid_record)
        expect(runner).to receive(:handle_failed_run)
        runner.run
      end
    end
  end
end
