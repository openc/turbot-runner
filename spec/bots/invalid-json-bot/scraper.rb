require 'json'

0.upto(9) do |n|
  record = {
    :licence_number => "XYZ#{n}",
    :source_url => 'http://example.com',
    :sample_date => '2014-06-01'
  }
  record = 'This is not JSON' if n == 5
  puts(record.to_json)
end
