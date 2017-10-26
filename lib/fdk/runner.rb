# Looks for call(context, input) function
# Executes it with input
# Responds with output

require 'json'

module FDK

    def self.handle(func)
        format = ENV['FN_FORMAT']
       if format == "json"
            obs = ""
            STDIN.each do |line|
                # STDERR.puts "LINE: --#{line}--"
                # STDERR.flush
                if line.strip == ""
                    # TODO: this isn't very robust, might break if user input has a blank line. :/
                    payload = JSON.parse(obs)
                    # STDERR.puts "payload: #{payload.inspect}"
                    c = Context.newFromJSON(payload)
                    # STDERR.puts "context: " + c.inspect
                    # STDERR.flush
                    body = payload['body']
                    if c.content_type == 'application/json'
                        body = JSON.parse(body)
                    end
                    # TODO: begin/rescue so we can respond with proper error response and code
                    s = FDK.single_event(func, c, body)
                    response = {
                        headers: {
                            'Content-Type' => 'application/json'
                        },
                        'status_code' => 200,
                        body: s,
                    }
                    STDOUT.puts response.to_json
                    STDOUT.puts
                    STDOUT.flush
                    obs = ""
                else
                    obs += line
                end
            end
        elsif format == "default"
            # TODO: check if content type json, and if so, parse it before passing it in
            c = Context.new()
            body = STDIN.read
            # STDERR.puts "ct: #{c.content_type}"
            if c.content_type == "application/json"
                # STDERR.puts "parsing json"
                body = JSON.parse(body)
            end
            puts FDK.single_event(func, c, body)
        else
            raise "Format #{format} not supported in Ruby FDK."
        end
    end

    def self.single_event(func, c, i)
        s = send func, c, i
        return s
    end
end
