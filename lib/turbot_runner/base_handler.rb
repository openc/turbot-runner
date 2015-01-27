module TurbotRunner
  class BaseHandler
    def handle_valid_record(record, data_type)
    end

    def handle_run_ended
    end

    def handle_invalid_record(record, data_type, error_message)
    end

    def handle_invalid_json(line)
    end
  end
end
