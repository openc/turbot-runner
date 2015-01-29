require 'json-schema'

module TurbotRunner
  module Validator
    extend self

    def validate(schema, record)
      # We must change directory for the relative paths in schemas to make sense.
      errors = Dir.chdir(SCHEMAS_PATH) do
        JSON::Validator.fully_validate(schema, record, :errors_as_objects => true)
      end

      # For now, we just handle the first error.
      error = errors[0]
      return if error.nil?

      case error[:failed_attribute]
      when 'Required'
        match = error[:message].match(/required property of '(.*)'/)
        missing_property = match[1]
        path = fragment_to_path("#{error[:fragment]}/#{missing_property}")

        {:type => :missing, :path => path}
      when 'OneOf'
        if error[:message].match(/did not match any/)
          path_elements = fragment_to_path(error[:fragment]).split('.')

          raise "Deeply nested OneOf error at: #{error[:fragment]}" unless path_elements.size == 1

          record_fragment = record[path_elements[0]]
          schema_fragments = schema['properties'][path_elements[0]]['oneOf']

          schema_fragments.each do |s|
            s['properties'].each do |k, v|
              next if v['enum'].nil?

              if v['enum'].include?(record_fragment[k])
                error1 = validate(s, record_fragment)
                return error1.merge(:path => "#{path_elements[0]}.#{error1[:path]}")
              end
            end
          end

          {:type => :one_of_no_matches, :path => fragment_to_path(error[:fragment])}
        else
          {:type => :one_of_many_matches, :path => fragment_to_path(error[:fragment])}
        end
      when 'MinLength'
        match = error[:message].match(/minimum string length of (\d+) in/)
        min_length = match[1].to_i
        {:type => :too_short, :path => fragment_to_path(error[:fragment]), :length => min_length}
      when 'MaxLength'
        match = error[:message].match(/maximum string length of (\d+) in/)
        max_length = match[1].to_i
        {:type => :too_long, :path => fragment_to_path(error[:fragment]), :length => max_length}
      when 'TypeV4'
        match = error[:message].match(/the following types?: ([\w\s,]+) in schema/)
        allowed_types = match[1].split(',').map(&:strip)
        {:type => :type_mismatch, :path => fragment_to_path(error[:fragment]), :allowed_types => allowed_types}
      when 'Enum'
        match = error[:message].match(/the following values: ([\w\s,]+) in schema/)
        allowed_values = match[1].split(',').map(&:strip)
        {:type => :enum_mismatch, :path => fragment_to_path(error[:fragment]), :allowed_values => allowed_values}
      else
        if error[:message].match(/must be of format yyyy-mm-dd/)
          {:type => :format_mismatch, :path => fragment_to_path(error[:fragment]), :expected_format => 'yyyy-mm-dd'}
        else
          {:type => :unknown, :path => fragment_to_path(error[:fragment]), :failed_attribute => error[:failed_attribute], :message => error[:message]}
        end
      end
    end

    def fragment_to_path(fragment)
      fragment.sub(/^#?\/*/, '').gsub('/', '.')
    end
  end
end
