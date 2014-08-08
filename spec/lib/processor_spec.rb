require 'json'
require 'turbot_runner'

describe TurbotRunner::Processor do
  describe '#process' do
    before do
      @handler = TurbotRunner::BaseHandler.new
      @data_type = 'primary data'
      script_config = {
        :data_type => @data_type,
        :identifying_fields => ['number']
      }
      script_runner = instance_double('ScriptRunner')
      allow(script_runner).to receive(:interrupt_and_mark_as_failed)
      @processor = TurbotRunner::Processor.new(script_runner, script_config, @handler)
    end

    context 'with valid record' do
      it 'calls Handler#handle_valid_record' do
        record = {
          'sample_date' => '2014-06-01',
          'source_url' => 'http://example.com/123',
          'number' => 123
        }
        expect(@handler).to receive(:handle_valid_record).with(record, @data_type)
        @processor.process(record.to_json)
      end
    end

    context 'with record missing required field' do
      before do
        @record = {
          'sample_date' => '2014-06-01',
          'number' => 123
        }
      end

      it 'calls Handler#handle_invalid_record' do
        expected_errors = ['Missing required attribute: source_url']
        expect(@handler).to receive(:handle_invalid_record).
          with(@record, @data_type, expected_errors)
        @processor.process(@record.to_json)
      end
    end

    context 'with record missing all identifying fields' do
      before do
        @record = {
          'sample_date' => '2014-06-01',
          'source_url' => 'http://example.com/123'
        }
      end

      it 'calls Handler#handle_invalid_record' do
        expected_errors = ['There were no values provided for any of the identifying fields: number']
        expect(@handler).to receive(:handle_invalid_record).
          with(@record, @data_type, expected_errors)
        @processor.process(@record.to_json)
      end
    end

    context 'with invalid JSON' do
      it 'calls Handler#handle_invalid_json' do
        line = 'this is not JSON'
        expect(@handler).to receive(:handle_invalid_json).with(line)
        @processor.process(line)
      end
    end
  end
end
