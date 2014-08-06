module TurbotRunner
  class BaseHandler
    def handle_valid_record(record, data_type)
      true
    end

    def handle_invalid_record(record, data_type, line)
    end

    def handle_invalid_json(line)
    end
  end
end
