require 'json'
require 'turbot_runner'

describe TurbotRunner::Processor do
  describe '#process' do
    before do
      @handler = TurbotRunner::BaseHandler.new
      @data_type = 'primary data'
      @processor = TurbotRunner::Processor.new(@handler, @data_type)
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

    context 'with invalid record' do
      it 'calls Handler#handle_invalid_record' do
        before do
          @record = {
            'sample_date' => '2014-06-01',
            'number' => 123
          }
        end

        expected_errors = ['Missing required attribute: source_url']
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
