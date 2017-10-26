10.times do |i|
    start = Time.now
    puts `echo '{"yo":"dawg #{i}"}' | fn call myapp /fdk-ruby`
    puts "time: #{Time.now - start}"
end
