require 'json'

0.upto(9) do |n|
  record = {
    :licence_number => "XYZ#{n % 5}",
    :source_url => 'http://example.com',
    :sample_date => '2014-06-01'
  }
  puts(record.to_json)
end
