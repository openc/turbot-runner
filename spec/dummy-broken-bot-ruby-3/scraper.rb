require 'json'

3.times do |n|
  puts({h: n}.to_json)
end
