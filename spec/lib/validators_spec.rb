require 'spec_helper'

describe 'custom validators' do
  describe 'for date' do
    before do
      @schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'format' => 'date'}
        }
      }
    end

    specify 'validate valid dates' do
      strings = [
        '2015-01-10',
        '2015-01-10T10:15:57',
        '2015-01-10T10:15:57Z',
        '2015-01-10T10:15:57+00:00',
        '2015-01-10T11:15:57+01:00',
        '2015-01-10T09:15:57-01:00',
        '2015-01-10 10:15:57 +0000',
        '2015-01-10 11:15:57 +0100',
        '2015-01-10 09:15:57 -0100',
      ]

      strings.each do |string|
        record = {'aaa' => string}
        expect([@schema, record]).to be_valid
      end
    end

    specify 'do not validator invalid dates' do
      strings = [
        'nonsense',
        '2015-01-nonsense',
        '2015:01:10',
        '2015/01/10',
      ]

      strings.each do |string|
        record = {'aaa' => string}
        expect([@schema, record]).not_to be_valid
      end
    end
  end
end
