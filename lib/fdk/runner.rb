# Looks for call(context, input) function
# Executes it with input
# Responds with output

module FDK
    def self.included(base)
        puts "MODULE FDK INCLUDED"
        p base
    end

    def self.handle(func)
        puts "Calling func: " + func.to_s
        if ENV['FN_FORMAT'] == "json"
            # TODO:
        else
            c = Context.new()
            i = {my: "input"}    
            FDK.single_event(func, c, i)
        end
    end
    def self.single_event(func, c, i)
        o = send func, c, i
        return o
    end
end
