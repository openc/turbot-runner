require 'json'

0.upto(9) do |n|
  record = {
    :licence_number => "XYZ#{n}",
    :source_url => 'http://example.com',
    :sample_date => '01/06/2014'
  }
  puts(record.to_json)
end
