require 'turbot_runner'

RSpec::Matchers.define(:fail_validation_with) do |expected_error|
  match do |record|
    schema_path = File.join(TurbotRunner::SCHEMAS_PATH, 'primary-data-schema.json')
    identifying_fields = ['number']
    expect(TurbotRunner::Validator.validate(schema_path, record, identifying_fields)).to eq(expected_error)
  end
end

RSpec::Matchers.define(:be_valid) do
  match do |record|
    schema_path = File.join(TurbotRunner::SCHEMAS_PATH, 'primary-data-schema.json')
    identifying_fields = ['number']
    expect(TurbotRunner::Validator.validate(schema_path, record, identifying_fields)).to eq(nil)
  end
end
