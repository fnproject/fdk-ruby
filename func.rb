require_relative 'lib/fdk'

def myhandler(context, input)
    STDERR.puts "call_id: #{context.call_id}"
    STDERR.puts "input received: #{input}"
    name = "World"
    nin = input['name']
    if nin && nin != ""
        name = nin
    end
    return {message: "Hello " + name.to_s + "!"}
end

FDK.handle(:myhandler)
