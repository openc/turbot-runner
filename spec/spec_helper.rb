require 'turbot_runner'

RSpec::Matchers.define(:fail_validation_with) do |expected_error|
  match do |record|
    identifying_fields = ['number']
    @error = TurbotRunner::Validator.validate('primary-data', record, identifying_fields, Set.new)
    expect(@error).to eq(expected_error)
  end

  failure_message do |actual|
    "Expected error to be #{expected_error}, but was #{@error}"
  end
end

RSpec::Matchers.define(:be_valid) do
  match do |record|
    identifying_fields = ['number']
    expect(TurbotRunner::Validator.validate('primary-data', record, identifying_fields, Set.new)).to eq(nil)
  end
end
