require 'json'
require 'fileutils'
require 'pathname'

module TurbotRunner
  class Runner
    RC_OK = 0
    RC_SCRAPER_FAILED = 1
    RC_TRANSFORMER_FAILED = 2

    attr_reader :base_directory

    def initialize(directory, options={})
      assert_absolute_path(directory)
      @base_directory = directory
      @config = load_config(directory)
      @record_handler = options[:record_handler]
      @log_to_file = options[:log_to_file]
      @timeout = options[:timeout]
      @scraper_provided = options[:scraper_provided]
      if options[:output_directory]
        assert_absolute_path(options[:output_directory])
        @output_directory = options[:output_directory]
      else
        @output_directory = File.join(@base_directory, 'output')
      end
    end

    def run
      set_up_output_directory

      if @scraper_provided
        scraper_succeeded = true
      else
        scraper_succeeded = run_script(scraper_config)
      end

      # Run the transformers even if the scraper fails
      transformers_succeeded = true
      transformers.each do |transformer_config|
        config = transformer_config.merge({
          :base_directory => @base_directory,
          :duplicates_allowed => duplicates_allowed,
        })
        transformers_succeeded = run_script(config, input_file=scraper_output_file) && transformers_succeeded
      end

      if !scraper_succeeded
        RC_SCRAPER_FAILED
      elsif !transformers_succeeded
        RC_TRANSFORMER_FAILED
      else
        RC_OK
      end
    end

    def set_up_output_directory
      FileUtils.mkdir_p(@output_directory)

      if !@scraper_provided
        FileUtils.rm_f(output_file('scraper', '.out'))
        FileUtils.rm_f(output_file('scraper', '.err'))
      end

      transformers.each do |transformer_config|
        FileUtils.rm_f(output_file(transformer_config[:file], '.out'))
        FileUtils.rm_f(output_file(transformer_config[:file], '.err'))
      end
    end

    def process_output(opts={})
      process_script_output(scraper_config, opts)

      transformers.each do |transformer_config|
        process_script_output(transformer_config.merge(:base_directory => @base_directory), opts)
      end
    end

    private
    def full_interpreter_path
      if language == "ruby"
        # Ensure we use the same ruby as the current interpreter when
        # creating a subshell. Necessary for OSX packaged version.
        RbConfig.ruby
      else
        # Assume the first python in PATH
        language
      end
    end

    def load_config(directory)
      manifest_path = File.join(directory, 'manifest.json')
      raise "Could not find #{manifest_path}" unless File.exist?(manifest_path)

      begin
        json = open(manifest_path) {|f| f.read}
        JSON.parse(json, :symbolize_names => true)
      rescue JSON::ParserError
        # TODO provide better error message
        raise "Could not parse #{manifest_path} as JSON"
      end
    end


    def run_script(script_config, input_file=nil)
      command = build_command(script_config[:file], input_file)
      script_runner = ScriptRunner.new(
        command,
        output_file(script_config[:file]),
        script_config,
        :record_handler => @record_handler,
        :timeout => @timeout
      )

      script_runner.run # returns boolean indicating success
    end

    def process_script_output(script_config, opts)
      # The first argument to the Processor constructor is a nil
      # Runner. This is because no running behaviour
      # (e.g. interruptions etc) is required; we just want to do
      # record handling.
      processor = Processor.new(nil, script_config, @record_handler)
      file = output_file(script_config[:file])
      File.open(file) do |f|
        f.each_line do |line|
          processor.process(line, opts)
        end
      end
    rescue Errno::ENOENT => e
      # We only want to catch ENOENT if the output file doesn't exist, and not
      # if, for instance, a schema file is missing.
      raise unless e.message == "No such file or directory - #{output_file(script_config[:file])}"
    end

    def build_command(script, input_file=nil)
      raise "Could not run #{script} with #{language}" unless script_extension == File.extname(script)
      command = "#{full_interpreter_path} #{additional_args} #{script} >#{output_file(script)}"
      command << " 2>#{output_file(script, '.err')}" if @log_to_file
      command << " <#{input_file}" unless input_file.nil?
      command
    end

    def output_file(script, extension='.out')
      basename = File.basename(script, script_extension)
      File.join(@output_directory, basename) + extension
    end

    def script_extension
      {
        'ruby' => '.rb',
        'python' => '.py',
      }[language]
    end

    def additional_args
      {
        'ruby' => "-r#{File.expand_path('../prerun.rb', __FILE__)}",
        'python' => '-u',
      }[language]
    end

    def scraper_config
      {
        :base_directory => @base_directory,
        :file => scraper_script,
        :data_type => scraper_data_type,
        :identifying_fields => scraper_identifying_fields,
        :duplicates_allowed => duplicates_allowed,
      }
    end

    def scraper_script
      "scraper#{script_extension}"
    end

    def transformers
      @config[:transformers] || []
    end

    def scraper_output_file
      File.join(@output_directory, 'scraper.out')
    end

    def language
      @config[:language].downcase
    end

    def scraper_data_type
      @config[:data_type]
    end

    def scraper_identifying_fields
      @config[:identifying_fields]
    end

    def duplicates_allowed
      @config[:duplicates_allowed]
    end

    def assert_absolute_path(path)
      unless Pathname.new(path).absolute?
        raise "#{path} must be an absolute path"
      end
    end
  end
end
