require 'spec_helper'

describe TurbotRunner::Utils do
  specify '.flatten' do
    hash = {
      'a' => {
        'b' => {
          'c' => '123',
          'd' => '124',
        },
        'e' => {
          'f' => '156',
        }
      }
    }

    expect(TurbotRunner::Utils.flatten(hash)).to eq({
      'a.b.c' => '123',
      'a.b.d' => '124',
      'a.e.f' => '156',
    })
  end
end
