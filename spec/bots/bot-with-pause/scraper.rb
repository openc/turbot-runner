require 'json'

0.upto(9) do |n|
  record = {
    :licence_number => "XYZ#{n}",
    :source_url => 'http://example.com',
    :sample_date => '2014-06-01'
  }
  puts(record.to_json)

  if n == 4
    $stderr.puts 'The scraper will sleep for ten seconds...'
    sleep 10
    $stderr.puts 'The scraper is resuming...'
  end
end
