require 'json'

$stderr.puts('hello from ruby')

puts({:n => 1, :hello => 'hello, 1'}.to_json)
puts({:n => 2, :hello => 'hello, 2'}.to_json)
puts({:n => 3}.to_json)
puts({:n => 4, :hello => 'hello, 4'}.to_json)
