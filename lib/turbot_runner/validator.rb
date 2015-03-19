require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/to_query'

module TurbotRunner
  module Validator
    extend self

    def validate(data_type, record, identifying_fields, seen_uids)
      schema_path = TurbotRunner.schema_path(data_type)
      error = Openc::JsonSchema.validate(schema_path, record)

      message = error.nil? ? nil : error[:message]

      if message.nil?
        identifying_hash = identifying_hash(record, identifying_fields)
        identifying_attributes = identifying_hash.reject {|k, v| v.nil? || v == ''}
        if identifying_attributes.empty?
          message = "There were no values provided for any of the identifying fields: #{identifying_fields.join(', ')}"
        end
      end

      if message.nil? && !seen_uids.nil?
        record_uid = record_uid(identifying_hash)
        if seen_uids.include?(record_uid)
          message = "Already seen record with these identifying fields: #{identifying_hash}"
        else
          seen_uids.add(record_uid)
        end
      end

      message
    end

    def identifying_hash(record, identifying_fields)
      TurbotRunner::Utils.flatten(record).slice(*identifying_fields)
    end

    def record_uid(identifying_hash)
      Digest::SHA1.hexdigest(identifying_hash.to_query)
    end
  end
end
