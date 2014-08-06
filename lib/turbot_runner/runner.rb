require 'json'
require 'fileutils'

module TurbotRunner
  class Runner
    attr_reader :directory

    def initialize(directory, options={})
      @directory = directory
      @config = load_config(directory)
      @record_handler = options[:record_handler]
      @log_to_file = options[:log_to_file]
      @timeout = options[:timeout]
    end

    def run
      FileUtils.rm_rf(output_directory)
      FileUtils.mkdir_p(output_directory)

      return false if not run_scraper

      transformers.each do |transformer|
        return false if not run_transformer(transformer)
      end

      true
    end

    def process_output
      return false if not process_scraper_output

      transformers.each do |transformer|
        return false if not process_transformer_output(transformer)
      end

      true
    end

    private
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

    def run_scraper
      run_script(scraper_script, scraper_data_type)
    end

    def run_transformer(transformer)
      run_script(
        transformer[:file],
        transformer[:data_type],
        input_file=scraper_output_file
      )
    end

    def run_script(script, data_type, input_file=nil)
      command = build_command(script, input_file)

      runner = ScriptRunner.new(
        command,
        output_file(script),
        data_type,
        :record_handler => @record_handler,
        :timeout => @timeout
      )

      runner.run
    end

    def process_scraper_output
      process_script_output(scraper_script, scraper_data_type)
    end

    def process_transformer_output(transformer)
      process_script_output(transformer[:file], transformer[:data_type])
    end

    def process_script_output(script, data_type)
      processor = Processor.new(nil, data_type, @record_handler)

      File.open(output_file(script)) do |f|
        f.each_line do |line|
          processor.process(line)
        end
      end
    end

    def build_command(script, input_file=nil)
      raise "Could not run #{script} with #{language}" unless script_extension == File.extname(script)
      path_to_script = File.join(@directory, script)
      command = "#{language} #{additional_args} #{path_to_script} >#{output_file(script)}"
      command << " 2>#{output_file(script, '.err')}" if @log_to_file
      command << " <#{input_file}" unless input_file.nil?

      command
    end

    def output_file(script, extension='.out')
      basename = File.basename(script, script_extension)
      File.join(output_directory, basename) + extension
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

    def scraper_script
      "scraper#{script_extension}"
    end

    def transformers
      @config[:transformers] || []
    end

    def scraper_output_file
      File.join(output_directory, 'scraper.out')
    end

    def language
      @config[:language].downcase
    end

    def scraper_data_type
      @config[:data_type]
    end

    def output_directory
      File.join(@directory, 'output')
    end
  end
end
