require_relative 'lib/fdk'

def myhandler(context, input)
    STDERR.puts "request_url: " + context.protocol['request_url']
    STDERR.puts "call_id: " + context.call_id
    STDERR.puts "input: " + input.to_s
    return {message: "Hello " + input['name'].to_s + "!"}
end

FDK.handle(:myhandler)
