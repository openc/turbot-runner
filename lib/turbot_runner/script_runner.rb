require 'timeout'

# This is a useful blog post:
# http://blog.robseaman.com/2008/12/12/sending-ctrl-c-to-a-subprocess-with-ruby

# Ensure that SIGINT is ignored by the process running this.
trap('INT') {}

module TurbotRunner
  class ScriptRunner
    def initialize(command, output_file, data_type, options={})
      @command = command
      @output_file = output_file

      record_handler = options[:record_handler] || BaseHandler.new  # A BaseHandler does nothing
      @processor = Processor.new(self, data_type, record_handler)

      @timeout = options[:timeout] || 3600
    end

    def run
      @interrupted = false
      @failed = false

      # Start a thread that spawns a subprocess that runs the script and
      # redirects the script's output to a file at a known location.
      script_thread = Thread.new { run_command(@command) }

      # Wait for the output file to be created, so that we can start to read
      # from it.
      begin
        f = File.open(@output_file)
      rescue Errno::ENOENT
        sleep 0.1
        retry
      end
        
      # Read from output file line by line until either we reach the end of the
      # file and the script has exited, or @interrupted becomes true.
      until @interrupted do
        begin
          line = f.readline
          @processor.process(line)
        rescue EOFError
          break unless script_thread.alive?
          sleep 0.1
        end
      end

      # script_thread may still be alive if we exited the loop above becuase
      # @interrupted became true, and so we must kill it.
      kill_running_processes if script_thread.alive?

      @failed ? false : script_thread.join.value
    ensure
      f.close if f
    end

    def interrupt
      @interrupted = true
    end

    def interrupt_and_mark_as_failed
      @interrupted = true
      @failed = true
    end

    private
    def run_command(command)
      begin
        Timeout::timeout(@timeout) do
          system(command)

          # A nil exitstatus indicates that the script was interrupted.  A
          # termsig of 2 indicates that the script was interrupted by a SIGINT.
          $?.exitstatus == 0 || ($?.exitstatus.nil? && $?.termsig == 2)
        end
      rescue Timeout::Error
        kill_running_processes
        false
      end
    end

    def kill_running_processes
      # Send SIGINT to each process in the current proceess group, having
      # already ensured that the current process itself ignores the signal.
      Process.kill('INT', 0)
    end
  end
end
