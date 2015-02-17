require 'turbot_runner'

RSpec::Matchers.define(:fail_validation_with) do |expected_error|
  match do |record|
    identifying_fields = ['number']
    expect(TurbotRunner::Validator.validate('primary-data', record, identifying_fields)).to eq(expected_error)
  end
end

RSpec::Matchers.define(:be_valid) do
  match do |record|
    identifying_fields = ['number']
    expect(TurbotRunner::Validator.validate('primary-data', record, identifying_fields)).to eq(nil)
  end
end
