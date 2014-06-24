require 'json'

STDIN.each_line do |line|
  raw_record = JSON.parse(line)

  transformed_record = {
    :n => raw_record['n'],
    :goodbye => raw_record['hello'].sub('hello', 'goodbye')
  }

  puts transformed_record.to_json
end
