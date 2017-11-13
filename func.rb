require_relative 'lib/fdk'
require 'json'

def myfunc(context, input)
    STDERR.puts "request_url: " + context.attributes['request_url']
    STDERR.puts "call_id: " + context.call_id
    STDERR.puts "input: " + input.to_s
    return {message: "Hello " + input['name'].to_s + "!"}
end

FDK.handle(:myfunc)
