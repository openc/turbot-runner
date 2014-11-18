require 'json'
require 'json-schema'

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
          record = JSON.parse(line)
          errors = validate(record)

          if errors.empty?
            begin
              @record_handler.handle_valid_record(record, @data_type)
            rescue InterruptRun
              @runner.interrupt if @runner
            end
          else
            @record_handler.handle_invalid_record(record, @data_type, errors)
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
        identifying_attributes = record.reject do |k, v|
          !@identifying_fields.include?(k) || v.nil? || v == ''
        end

        if identifying_attributes.empty?
          messages << "There were no values provided for any of the identifying fields: #{@identifying_fields.join(', ')}"
        end
      end

      messages
    end

    def schema
      @schema ||= get_schema
    end

    def get_schema
      hyphenated_name = @data_type.to_s.gsub("_", "-").gsub(" ", "-")
      File.expand_path("../../../schema/schemas/#{hyphenated_name}-schema.json", __FILE__)
    end
  end
end
