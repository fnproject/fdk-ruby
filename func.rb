require_relative 'lib/fdk'
require 'json'

def myfunc(context, input)
    # Do some work here
    if input != ""
        input = JSON.parse(input)
    end
    STDERR.puts "request_url: " + context.request_url
    STDERR.puts "call_id: " + context.call_id
    STDERR.puts "input: " + input.to_s
    return {hello: "I got: " + input.to_s + "!"}.to_json
end

FDK.handle(:myfunc)
