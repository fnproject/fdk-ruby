require_relative 'lib/fdk'

def myfunc(context, input)
    # Do some work here
    STDERR.puts "request_url: " + context.request_url
    STDERR.puts "call_id: " + context.call_id
    STDERR.puts "input: " + input.to_s
    return "I got: " + input.to_s + "!"
end

FDK.handle(:myfunc)
