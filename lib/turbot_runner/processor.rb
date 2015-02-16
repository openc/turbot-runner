require 'openc/json_schema'

module TurbotRunner
  class Processor
    def initialize(runner, script_config, record_handler)
      @runner = runner
      @data_type = script_config[:data_type]
      @identifying_fields = script_config[:identifying_fields]
      @record_handler = record_handler
    end

    def process(line)
      begin
        if line.strip == "RUN ENDED"
          @record_handler.handle_run_ended
          @runner.interrupt if @runner
        else
          record = Openc::JsonSchema.convert_dates(schema_path, JSON.parse(line))

          error_message = validate(record)

          if error_message.nil?
            begin
              @record_handler.handle_valid_record(record, @data_type)
            rescue InterruptRun
              @runner.interrupt if @runner
            end
          else
            @record_handler.handle_invalid_record(record, @data_type, error_message)
            @runner.interrupt_and_mark_as_failed if @runner
          end
        end
      rescue JSON::ParserError
        @record_handler.handle_invalid_json(line)
        @runner.interrupt_and_mark_as_failed if @runner
      end
    end

    def interrupt
      @runner.interrupt
    end

    def validate(record)
      error = Openc::JsonSchema.validate(schema_path, record)

      message = nil

      if error.nil?
        identifying_attributes = record.reject do |k, v|
          !@identifying_fields.include?(k) || v.nil? || v == ''
        end

        if identifying_attributes.empty?
          message = "There were no values provided for any of the identifying fields: #{@identifying_fields.join(', ')}"
        end
      else
        message = case error[:type]
        when :missing
          "Missing required property: #{error[:path]}"
        when :one_of_no_matches
          "No match for property: #{error[:path]}"
        when :one_of_many_matches
          "Multiple possible matches for property: #{error[:path]}"
        when :too_short
          "Property too short: #{error[:path]} (must be at least #{error[:length]} characters)"
        when :too_long
          "Property too long: #{error[:path]} (must be at most #{error[:length]} characters)"
        when :type_mismatch
          "Property of wrong type: #{error[:path]} (must be of type #{error[:allowed_types].join(', ')})"
        when :enum_mismatch
          "Property not an allowed value: #{error[:path]} (must be one of #{error[:allowed_values].join(', ')})"
        when :format_mismatch
          "Property not of expected format: #{error[:path]} (must be of format #{error[:expected_format]})"
        when :unknown
          error[:message]
        end
      end

      message
    end

    def schema_path
      hyphenated_name = @data_type.to_s.gsub("_", "-").gsub(" ", "-")
      File.join(SCHEMAS_PATH, "#{hyphenated_name}-schema.json")
    end

    class ConversionError < StandardError; end
  end
end
