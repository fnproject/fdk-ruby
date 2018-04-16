# assumes function deployed at least once
puts `fn routes update myapp /fdk-ruby --format default`
sleep 1
puts "Cold"
5.times do |i|
    start = Time.now
    puts `echo '{"name":"dawg #{i}"}' | fn call myapp /fdk-ruby`
    puts "time: #{Time.now - start}"
    puts
end
puts `fn routes update myapp /fdk-ruby --format json`
sleep 1
puts "Hot"
5.times do |i|
    start = Time.now
    puts `echo '{"name":"dawg #{i}"}' | fn call myapp /fdk-ruby`
    puts "time: #{Time.now - start}"
    puts
end
