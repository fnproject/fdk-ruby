# assumes function deployed at least once
puts `fn update function examples hello --format default`
sleep 1
puts "Cold"
5.times do |i|
    start = Time.now
    puts `echo "dawg #{i}" | fn invoke examples hello`
    puts "time: #{Time.now - start}"
    puts
end
puts `fn update function examples hello --format json`
sleep 1
puts "Hot"
5.times do |i|
    start = Time.now
    puts `echo '{"name":"dawg #{i}"}' | fn invoke examples hello`
    puts "time: #{Time.now - start}"
    puts
end
