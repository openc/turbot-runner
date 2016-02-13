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

RSpec::Matchers.define(:have_output) do |script, expected|
  match do |runner|
    expected_path = File.join('spec', 'outputs', expected)
    @expected_output = File.readlines(expected_path).map {|line| JSON.parse(line)}
    actual_path = File.join(runner.base_directory, 'output', "#{script}.out")
    @actual_output = File.readlines(actual_path).map {|line| JSON.parse(line)}
    expect(@expected_output).to eq(@actual_output)
  end

  failure_message do |actual|
    "Expected output to be #{@expected_output}, but was #{@actual_output}"
  end
end

RSpec::Matchers.define(:have_error_output_matching) do |script, expected|
  match do |runner|
    actual_path = File.join(runner.base_directory, 'output', "#{script}.err")
    actual_output = File.read(actual_path)
    expect(actual_output).to match(expected)
  end
end

RSpec::Matchers.define(:succeed) do
  match do |runner|
    @actual_run = runner.run
    expect(@actual_run).to eq(TurbotRunner::Runner::RC_OK)
  end

  failure_message do |actual|
    "Expected output to be TurbotRunner::Runner::RC_OK, but was #{@actual_run}"
  end
end

RSpec::Matchers.define(:fail_in_scraper) do
  match do |runner|
    @actual_run = runner.run
    expect(@actual_run).to eq(TurbotRunner::Runner::RC_SCRAPER_FAILED)
  end

  failure_message do |actual|
    "Expected output to be TurbotRunner::Runner::RC_SCRAPER_FAILED, but was #{@actual_run}"
  end
end

RSpec::Matchers.define(:fail_in_transformer) do
  match do |runner|
    @actual_run = runner.run
    expect(@actual_run).to eq(TurbotRunner::Runner::RC_TRANSFORMER_FAILED)
  end

  failure_message do |actual|
    "Expected output to be TurbotRunner::Runner::RC_TRANSFORMER_FAILED, but was #{@actual_run}"
  end
end
