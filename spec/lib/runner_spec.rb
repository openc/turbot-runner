require 'json'
require 'turbot_runner'

describe TurbotRunner::Runner do
  after(:all) do
    puts
    puts 'If all specs passed, you should now run `ruby spec/manual.rb`'
  end

  describe '#run' do
    context 'with a bot written in ruby' do
      before do
        @runner = test_runner('ruby-bot')
      end

      it 'produces expected output' do
        @runner.run
        expect(@runner).to have_output('scraper', 'full-scraper.out')
      end

      it 'returns true' do
        expect(@runner).to succeed
      end
    end

    context 'with a bot written in python' do
      before do
        @runner = test_runner('python-bot')
      end

      it 'produces expected output' do
        @runner.run
        expect(@runner).to have_output('scraper', 'full-scraper.out')
      end
    end

    context 'with a bot with a transformer' do
      before do
        @runner = test_runner('bot-with-transformer')
      end

      it 'produces expected outputs' do
        @runner.run
        expect(@runner).to have_output('scraper', 'full-scraper.out')
        expect(@runner).to have_output('transformer', 'full-transformer.out')
      end

      it 'returns true' do
        expect(@runner).to succeed
      end
    end

    context 'with a bot with multiple transformers' do
      before do
        @runner = test_runner('bot-with-transformers')
      end

      it 'produces expected outputs' do
        @runner.run
        expect(@runner).to have_output('scraper', 'full-scraper.out')
        expect(@runner).to have_output('transformer1', 'full-transformer.out')
        expect(@runner).to have_output('transformer2', 'full-transformer.out')
      end

      it 'returns true' do
        expect(@runner).to succeed
      end
    end

    context 'with a bot that logs' do
      context 'when logging to file enabled' do
        it 'logs to file' do
          expected_log = "doing...\ndone\n"
          runner = test_runner('logging-bot', :log_to_file => true)
          runner.run
          expect(runner).to have_error_output_matching('scraper', expected_log)
        end
      end

      context 'when logging to file not enabled' do
        xit 'logs to stderr' do
          # This is tested in manual.rb
        end
      end
    end

    context 'with a bot that outputs RUN ENDED' do
      before do
        @runner = test_runner('bot-that-emits-run-ended', :log_to_file => true)
      end

      it 'calls handle_snapshot_ended on the handler' do
        expect_any_instance_of(TurbotRunner::BaseHandler).to receive(:handle_snapshot_ended)
        @runner.run
      end

      it 'interrupts the run' do
        expect_any_instance_of(TurbotRunner::ScriptRunner).to receive(:interrupt)
        @runner.run
      end
    end

    context 'with a bot that outputs SNAPSHOT ENDED' do
      before do
        @runner = test_runner('bot-that-emits-snapshot-ended', :log_to_file => true)
      end

      it 'calls handle_snapshot_ended on the handler' do
        expect_any_instance_of(TurbotRunner::BaseHandler).to receive(:handle_snapshot_ended)
        @runner.run
      end

      it 'interrupts the run' do
        expect_any_instance_of(TurbotRunner::ScriptRunner).to receive(:interrupt)
        @runner.run
      end
    end

    context 'with a bot that crashes in scraper' do
      before do
        @runner = test_runner('bot-that-crashes-in-scraper', :log_to_file => true)
      end

      it 'returns false' do
        expect(@runner).to fail_in_scraper
      end

      it 'writes error to stderr' do
        @runner.run
        expect(@runner).to have_error_output_matching('scraper', /Oh no/)
      end

      it 'still runs the transformers' do
        expect(@runner).to receive(:run_script).once.with(
          hash_including(:file=>"scraper.rb"))
        expect(@runner).to receive(:run_script).once.with(
          hash_including(:file=>"transformer1.rb"), anything)
        @runner.run
      end
    end

    context 'with a bot that expects a file to be present in the working directory' do
      before do
        @runner = test_runner('bot-that-expects-file')
      end

      it 'returns true' do
        expect(@runner).to succeed
      end
    end

    context 'with a bot that crashes in transformer' do
      before do
        @runner = test_runner('bot-that-crashes-in-transformer', :log_to_file => true)
      end

      it 'returns false' do
        expect(@runner).to fail_in_transformer
      end

      it 'writes error to stderr' do
        @runner.run
        expect(@runner).to have_error_output_matching('transformer2', /Oh no/)
      end
    end

    context 'with a bot that is interrupted in scraper' do
      xit 'produces truncated output' do
        # This is tested in manual.rb
      end
    end

    context 'with a handler that interrupts the runner' do
      before do
        class Handler < TurbotRunner::BaseHandler
          def initialize
            @count = 0
            super
          end

          def handle_valid_record(record, data_type)
            @count += 1
            raise TurbotRunner::InterruptRun if @count >= 5
          end
        end

        @runner = test_runner('slow-bot',
          :record_handler => Handler.new,
          :log_to_file => true
        )
      end

      it 'produces expected output' do
        @runner.run
        expect(@runner).to have_output('scraper', 'truncated-scraper.out')
      end

      it 'returns true' do
        expect(@runner).to succeed
      end
    end

    context 'with a scraper that produces an invalid record' do
      it 'returns false' do
        @runner = test_runner('invalid-record-bot')
        expect(@runner).to fail_in_scraper
      end
    end

    context 'with a scraper that produces invalid JSON' do
      it 'returns false' do
        @runner = test_runner('invalid-json-bot')
        expect(@runner).to fail_in_scraper
      end
    end

    context 'with a scraper that hangs' do
      # XXX This spec fails because the loop in ScriptRunner#run that
      # reads lines from the output file doesn't start until the
      # output file is created; however, the way we're redirecting
      # stdout using the shell means the file doesn't get created
      # until
      it 'returns false' do
        @runner = test_runner('bot-with-pause',
          :timeout => 1,
          :log_to_file => true
        )
        expect(@runner).to fail_in_scraper
      end
    end

    context 'with a bot that emits an invalid sample date' do
      before do
        @runner = test_runner('bot-with-invalid-sample-date')
      end

      it 'returns false' do
        expect(@runner).to fail_in_scraper
      end
    end

    context 'with a bot with an invalid data type' do
      before do
        @runner = test_runner('bot-with-invalid-data-type')
      end

      it 'raises InvalidDataType' do
        expect{@runner.run}.to raise_error(TurbotRunner::InvalidDataType)
      end
    end

    context 'with a bot that produces duplicate data' do
      before do
        @runner = test_runner('bot-that-produces-duplicates')
      end

      it 'raises returns false' do
        expect(@runner).to fail_in_scraper
      end
    end

    context 'with a bot that is expected to produce duplicate data' do
      before do
        @runner = test_runner('bot-that-is-allowed-to-produce-duplicates')
      end

      it 'raises returns false' do
        expect(@runner).to succeed
      end
    end

    context 'when the scraped data is provided' do
      before do
        @runner = test_runner('bot-with-transformer', :scraper_provided => true)
        @runner.set_up_output_directory
        FileUtils.cp(
          File.join('spec', 'outputs', 'full-scraper.out'),
          File.join(File.dirname(__FILE__), '../bots', 'bot-with-transformer', 'output', 'scraper.out')
        )
      end

      it 'does not run scraper' do
        expect(@runner).to receive(:run_script).once.with(
          hash_including(:file => 'transformer.rb'), anything
        )
        @runner.run
      end

      it 'succeeds' do
        expect(@runner).to succeed
      end

      it 'produces expected transformed output' do
        @runner.run
        expect(@runner).to have_output('transformer', 'full-transformer.out')
      end
    end
  end

  describe '#process_output' do
    before do
      class Handler < TurbotRunner::BaseHandler
        attr_reader :records_seen

        def initialize
          @records_seen = Hash.new(0)
          super
        end

        def handle_valid_record(record, data_type)
          @records_seen[data_type] += 1
        end
      end

      @handler = Handler.new
    end

    context 'with a bot that runs correctly' do
      before do
        test_runner('bot-with-transformer').run
      end

      it 'calls handler once for each line of output' do
        runner = test_runner('bot-with-transformer',
          :record_handler => @handler
        )

        runner.process_output
        expect(@handler.records_seen['primary data']).to eq(10)
        expect(@handler.records_seen['simple-licence']).to eq(10)
      end

      it 'passes opts to processor.process' do
        runner = test_runner('bot-with-transformer',
          :record_handler => @handler
        )
        opts = {frob: 5}
        processor = double('processor')
        allow(TurbotRunner::Processor).to receive(:new).and_return(processor)
        expect(processor).to receive(:process).with(anything, opts).at_least(:once)
        runner.process_output(opts)
      end

      context 'when skip_data_types is set' do
        it 'skips the data type' do
          runner = test_runner('bot-with-transformer',
            :record_handler => @handler
          )

          runner.process_output(skip_data_types: ['primary data'])
          expect(@handler.records_seen['primary data']).to eq(0)
          expect(@handler.records_seen['simple-licence']).to eq(10)
        end
      end
    end

    context 'with a bot that crashes immediately' do
      before do
        test_runner('bot-that-crashes-immediately').run
      end

      it 'can cope with the empty files' do
        runner = test_runner('bot-that-crashes-immediately',
          :record_handler => @handler
        )

        runner.process_output
      end
    end
  end

  describe '#set_up_output_directory' do
    before do
      @runner = test_runner('bot-with-transformer')
    end

    it 'clears existing output' do
      @runner.set_up_output_directory
      path = File.join(@runner.base_directory, 'output', 'scraper.out')
      FileUtils.touch(path)

      @runner.set_up_output_directory
      expect(File.exist?(path)).to be(false)
    end

    it 'does not clear existing files that are not output files' do
      @runner.set_up_output_directory
      path = File.join(@runner.base_directory, 'output', 'stdout')
      FileUtils.touch(path)

      @runner.set_up_output_directory
      expect(File.exist?(path)).to be(true)
    end
  end
end
