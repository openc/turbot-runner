require 'json'

$stderr.puts('hello')

puts({h: 1}.to_json)
raise "oops"
