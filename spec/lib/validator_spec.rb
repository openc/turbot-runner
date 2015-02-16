require 'spec_helper'

describe TurbotRunner::Validator do
  describe '.validate' do
    specify 'with valid record' do
      record = {
        'sample_date' => '2014-06-01',
        'source_url' => 'http://example.com/123',
        'number' => 123
      }
      expect(record).to be_valid
    end

    specify 'with record missing required field' do
      record = {
        'sample_date' => '2014-06-01',
        'number' => 123
      }
      expected_error = 'Missing required property: source_url'
      expect(record).to fail_validation_with(expected_error)
    end

    specify 'with record missing all identifying fields' do
      record = {
        'sample_date' => '2014-06-01',
        'source_url' => 'http://example.com/123'
      }
      expected_error = 'There were no values provided for any of the identifying fields: number'
      expect(record).to fail_validation_with(expected_error)
    end

    specify 'with record with empty sample_date' do
      record = {
        'sample_date' => '',
        'source_url' => 'http://example.com/123',
        'number' => 123
      }
      expected_error = 'Property not of expected format: sample_date (must be of format yyyy-mm-dd)'
      expect(record).to fail_validation_with(expected_error)
    end

    specify 'with record with invalid sample_date' do
      record = {
        'sample_date' => '2014-06-00',
        'source_url' => 'http://example.com/123',
        'number' => 123
      }
      expected_error = 'Property not of expected format: sample_date (must be of format yyyy-mm-dd)'
      expect(record).to fail_validation_with(expected_error)
    end
  end
end
