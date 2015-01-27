require 'turbot_runner'

RSpec::Matchers.define(:fail_validation_with) do |expected|
  match do |actual|
    schema, record = actual

    error = TurbotRunner::Validator.validate(schema, record)
    expect(error).to eq(expected)
  end
end

RSpec::Matchers.define(:be_valid) do
  match do |actual|
    schema, record = actual

    error = TurbotRunner::Validator.validate(schema, record)
    expect(error).to eq(nil)
  end
end

