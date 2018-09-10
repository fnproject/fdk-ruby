# assumes function deployed at least once
puts `fn update route examples /hello-ruby --format default`
sleep 1
puts "Cold"
5.times do |i|
    start = Time.now
    puts `echo "dawg #{i}" | fn call examples /hello-ruby`
    puts "time: #{Time.now - start}"
    puts
end
puts `fn update route examples /hello-ruby --format json`
sleep 1
puts "Hot"
5.times do |i|
    start = Time.now
    puts `echo '{"name":"dawg #{i}"}' | fn call examples /hello-ruby`
    puts "time: #{Time.now - start}"
    puts
end
