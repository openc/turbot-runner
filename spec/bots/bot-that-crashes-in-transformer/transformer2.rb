require 'json'

STDIN.each_line do |line|
  raw_record = JSON.parse(line)

  transformed_record = {
    :company_name => 'Foo Widgets',
    :company_jurisdiction => 'gb',
    :licence_number => raw_record['licence_number'],
    :source_url => raw_record['source_url'],
    :sample_date => raw_record['sample_date'],
  }

  puts transformed_record.to_json

  raise 'Oh no' if raw_record['licence_number'] == 'XYZ4'
end
