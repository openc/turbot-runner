require 'json'

STDIN.each_line do |line|
  raw_record = JSON.parse(line)

  transformed_record = {
    :p => raw_record['n'],
  }

  puts transformed_record.to_json
end
