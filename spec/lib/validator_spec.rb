require 'turbot_runner'

describe TurbotRunner::Validator do
  describe 'validation' do
    specify 'when record is valid' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'required' => ['aaa'],
      }
      record = {'aaa' => 'zzz'}

      expect([schema, record]).to be_valid
    end

    specify 'when required top-level property missing' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'required' => ['aaa'],
      }
      record = {}

      expect([schema, record]).to fail_validation_with(
        :type => :missing,
        :path => 'aaa'
      )
    end

    specify 'when required nested property missing' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'required' => ['aaa'],
        'properties' => {
          'aaa' => {
            'type' => 'object',
            'required' => ['bbb'],
          }
        }
      }
      record = {'aaa' => {}}

      expect([schema, record]).to fail_validation_with(
        :type => :missing,
        :path => 'aaa.bbb'
      )
    end

    context 'when none of oneOf options match' do
      specify 'and we are switching on an enum field' do
        schema = {
          '$schema' => 'http://json-schema.org/draft-04/schema#',
          'type' => 'object',
          'required' => ['aaa'],
          'properties' => {
            'aaa' => {
              'type' => 'object',
              'oneOf' => [{
                'properties' => {
                  'a_type' => {
                    'enum' => ['a1']
                  },
                  'a_properties' => {
                    'type' => 'object',
                    'required' => ['bbb'],
                  }
                }
              }, {
                'properties' => {
                  'a_type' => {
                    'enum' => ['a2']
                  },
                  'a_properties' => {
                    'type' => 'object',
                    'required' => ['ccc']
                  }
                }
              }]
            }
          }
        }
      
        record = {'aaa' => {'a_type' => 'a1', 'a_properties' => {}}}

        expect([schema, record]).to fail_validation_with(
          :type => :missing,
          :path => 'aaa.a_properties.bbb'
        )
      end

      specify 'and we are not switching on an enum field' do
        schema = {
          '$schema' => 'http://json-schema.org/draft-04/schema#',
          'type' => 'object',
          'required' => ['aaa'],
          'properties' => {
            'aaa' => {
              'type' => 'object',
              'oneOf' => [{
                'properties' => {
                  'bbb' => {
                    'type' => 'object',
                    'required' => ['ccc'],
                  }
                }
              }, {
                'properties' => {
                  'bbb' => {
                    'type' => 'object',
                    'required' => ['ddd']
                  }
                }
              }]
            }
          }
        }
      
        record = {'aaa' => {'bbb' => {}}}

        expect([schema, record]).to fail_validation_with(
          :type => :one_of_no_matches,
          :path => 'aaa'
        )
      end
    end

    specify 'when top-level property too short' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'minLength' => 2}
        }
      }
      record = {'aaa' => 'x'}

      expect([schema, record]).to fail_validation_with(
        :type => :too_short,
        :path => 'aaa',
        :length => 2
      )
    end

    specify 'when nested property too short' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {
            'type' => 'object',
            'properties' => {
              'bbb' => {'minLength' => 2}
            }
          }
        }
      }
      record = {'aaa' => {'bbb' => 'x'}}

      expect([schema, record]).to fail_validation_with(
        :type => :too_short,
        :path => 'aaa.bbb',
        :length => 2
      )
    end

    specify 'when property too long' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'maxLength' => 2}
        }
      }
      record = {'aaa' => 'xxx'}

      expect([schema, record]).to fail_validation_with(
        :type => :too_long,
        :path => 'aaa',
        :length => 2
      )
    end

    specify 'when property of wrong type and many types allowed' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => ['number', 'string']}
        }
      }
      record = {'aaa' => ['xxx']}

      expect([schema, record]).to fail_validation_with(
        :type => :type_mismatch,
        :path => 'aaa',
        :allowed_types => ['number', 'string']
      )
    end

    specify 'when property of wrong type and single type allowed' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'number'}
        }
      }
      record = {'aaa' => 'xxx'}

      expect([schema, record]).to fail_validation_with(
        :type => :type_mismatch,
        :path => 'aaa',
        :allowed_types => ['number']
      )
    end

    specify 'when property not in enum' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'enum' => ['a', 'b', 'c']}
        }
      }
      record = {'aaa' => 'z'}

      expect([schema, record]).to fail_validation_with(
        :type => :enum_mismatch,
        :path => 'aaa',
        :allowed_values => ['a', 'b', 'c']
      )
    end
  end
end

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
