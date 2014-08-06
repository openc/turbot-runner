require 'json'
require 'json-schema'

module TurbotRunner
  class Processor
    def initialize(runner, data_type, record_handler)
      @runner = runner
      @data_type = data_type
      @record_handler = record_handler
    end

    def process(line)
      begin
        record = JSON.parse(line)
        errors = validate(record)

        if errors.empty?
          rc = @record_handler.handle_valid_record(record, @data_type)
          @runner.interrupt unless rc
        else
          @record_handler.handle_invalid_record(record, @data_type, errors)
          @runner.interrupt_and_mark_as_failed
        end
      rescue JSON::ParserError
        @record_handler.handle_invalid_json(line)
        @runner.interrupt_and_mark_as_failed
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
