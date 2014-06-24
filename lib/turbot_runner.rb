require 'open3'

module TurbotRunner
  class BaseRunner
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

      @schemas = {}
    end

    def run(opts={})
      validation_required = opts[:validate] || true

      command = "#{interpreter_for(scraper_file)} #{scraper_file}"
      data_type = @config['data_type']

      run_script_each_line(command) do |line|
        record = JSON.parse(line)
        errors = validate(record, data_type)

        if errors.empty?
          process_valid(record, data_type)
        else
          process_invalid(record, data_type)
        end

        transformers.each do |transformer|
          file = File.join(@bot_directory, transformer['file'])
          command1 = "#{interpreter_for(file)} #{file}"
          data_type1 = transformer['data_type']

          run_script_each_line(command1, :input => line) do |line1|
            record1 = JSON.parse(line1)

            errors = validate(record1, data_type1)

            if errors.empty?
              process_valid(record1, data_type1)
            else
              process_invalid(record1, data_type1)
            end
          end
        end
      end
    end

    private
    def transformers
      @config['transformers']
    end

    def validate(record, data_type)
      schema = get_schema(data_type)
      JSON::Validator.fully_validate(schema, record, errors_as_objects => true)
    end

    def get_schema(data_type)
      if !@schemas.has_key?(data_type)
        hyphenated_name = data_type.to_s.gsub("_", "-").gsub(" ", "-")
        @schemas[data_type] = File.expand_path("../../schema/schemas/#{hyphenated_name}-schema.json", __FILE__)
      end

      @schemas[data_type]
    end

    def process_valid(record, data_type)
      raise NotImplementedError
    end

    def process_invalid(record, data_type)
      raise NotImplementedError
    end

    def run_script_each_line(command, options={})
      # TODO: handle timeouts, errors
      Open3::popen3(command) do |stdin, stdout, stderr, wait_thread|
        if options[:input]
          stdin.puts(options[:input])
          stdin.close
        end

        timeout = options[:timeout] || 3600

        loop do
          begin
            result = stdout.readline.strip
            yield result unless result.empty?
          rescue EOFError
            break
          end
        end
      end
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
        'ruby'
      when /\.py$/
        'python'
      else
        raise "Could not run #{file}"
      end
    end
  end
end
