require 'json'
require 'open3'
require 'timeout'

module TurbotRunner
  class ScriptError < StandardError; end

  class BaseRunner

    attr_reader :wait_thread

    def initialize(bot_directory)
      @bot_directory = bot_directory

      manifest_path = File.join(bot_directory, 'manifest.json')
      raise "Could not find #{manifest_path}" unless File.exist?(manifest_path)

      begin
        @config = JSON.parse(open(manifest_path) {|f| f.read})
      rescue JSON::ParserError
        # TODO provide better error message
        raise "Could not parse #{manifest_path} as JSON"
      end

      @status = :initialized
      @interrupted = false
      @schemas = {}
    end

    def run(opts={})
      @status = :running
      validation_required = opts[:validate] || true

      command = "#{interpreter_for(scraper_file)} #{scraper_file}"
      data_type = @config['data_type']

      scraper_runner = CommandRunner.new(command)

      transformers.each do |config|
        file = File.join(@bot_directory, config['file'])
        command = "#{interpreter_for(file)} #{file}"
        transformer_runner = CommandRunner.new(command)
        config['runner'] = transformer_runner
      end

      begin
        until @interrupted do
          line = scraper_runner.get_next_line
          break if line.nil?

          begin
            record = JSON.parse(line)
          rescue JSON::ParserError
            handle_non_json_output(line)
            next
          end

          errors = validate(record, data_type)

          if errors.empty?
            handle_valid_record(record, data_type)

            transformers.each do |transformer|
              data_type1 = transformer['data_type']

              runner = transformer['runner']
              runner.send_line(line)
              line1 = runner.get_next_line

              begin
                record1 = JSON.parse(line1)
              rescue JSON::ParserError
                handle_non_json_output(line1)
                next
              end

              errors = validate(record1, data_type1)

              if errors.empty?
                handle_valid_record(record1, data_type1)
              else
                handle_invalid_record(record1, data_type1, errors)
              end
            end
          else
            handle_invalid_record(record, data_type, errors)
          end
        end
        if @interrupted
          @status = :interrupted
          handle_interrupted_run
        else
          @status = :successful
          handle_successful_run
        end
      rescue ScriptError => e
        if @interrupted
          @status = :interrupted
          handle_interrupted_run
        else
          @status = :failed
          handle_failed_run
        end
      end
    ensure
      scraper_runner.close unless scraper_runner.nil?
      transformers.each do |transformer|
        transformer['runner'].close unless transformer['runner'].nil?
      end
    end

    def successful?
      @status == :successful
    end

    def interrupt
      @interrupted = true
    end

    private
    def transformers
      @config['transformers'] || []
    end

    def validate(record, data_type)
      schema = get_schema(data_type)
      errors = JSON::Validator.fully_validate(schema, record, :errors_as_objects => true)
      messages = errors.map do |error|
        case error[:message]
        when /The property '#\/' did not contain a required property of '(\w+)'/
          "Missing required attribute: #{Regexp.last_match(1)}"
        else
          error[:message]
        end
      end

      if messages.empty?
        identifying_fields = identifying_fields_for_data_type(data_type)

        hash = Hash.new
        identifying_fields.each do |k|
          hash[k] = record[k] if record.has_key?(k)
        end

        if hash.empty?
          messages << "Missing attributes for identifying fields: #{identifying_fields.join(', ')}"
        end
      end

      messages
    end

    def identifying_fields_for_data_type(data_type)
      if data_type == @config['data_type']
        @config['identifying_fields']
      else
        transformers = @config['transformers'].select {|transformer| transformer['data_type'] == data_type}
        raise "Expected to find precisely 1 transformer matching #{data_type} in manifest.json" unless transformers.size == 1
        transformers[0]['identifying_fields']
      end
    end

    def get_schema(data_type)
      if !@schemas.has_key?(data_type)
        hyphenated_name = data_type.to_s.gsub("_", "-").gsub(" ", "-")
        @schemas[data_type] = File.expand_path("../../schema/schemas/#{hyphenated_name}-schema.json", __FILE__)
      end

      @schemas[data_type]
    end

    def handle_valid_record(record, data_type)
      raise NotImplementedError
    end

    def handle_invalid_record(record, data_type, errors)
      raise NotImplementedError
    end

    def handle_non_json_output(line)
      raise NotImplementedError
    end

    def handle_successful_run
    end

    def handle_interrupted_run
    end

    def handle_failed_run
      raise NotImplementedError
    end

    def scraper_file
      candidates = Dir.glob(File.join(@bot_directory, 'scraper.{rb,py}'))
      case candidates.size
      when 0
        raise 'Could not find scraper to run'
      when 1
        candidates.first
      else
        raise "Found multiple scrapers: #{candidates.join(', ')}"
      end
    end

    def interpreter_for(file)
      case file
      when /\.rb$/
        prerun = File.expand_path("../prerun.rb", __FILE__)
        "ruby -r#{prerun}"
      when /\.py$/
        'python -u'
      else
        raise "Could not run #{file}"
      end
    end
  end

  class CommandRunner
    def initialize(command, opts={})
      @command = command
      @timeout = opts[:timeout] ||= 3600
      @stdin, @stdout, @wait_thread = Open3.popen2(command)
    end

    def get_next_line
      begin
        Timeout::timeout(@timeout) { @stdout.gets }
      rescue Timeout::Error
        STDOUT.puts("#{@command} produced no output for #{@timeout} seconds")
        raise ScriptError
      rescue EOFError
        raise ScriptError unless @wait_thread.value.success?
        return nil
      end
    end

    def send_line(line)
      @stdin.puts(line)
    end

    def close
      @stdin.close
      @stdout.close
    end
  end
end
