require 'webrick'
require 'fileutils'

# Looks for call(context, input) function
# Executes it with input
# Responds with output


class FunctionServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_POST (request, response)

    response.status = 200
    response.body = "hello"

  end
end

module FDK
  def self.handle(function, input_stream: STDIN, output_stream: STDOUT)
    format = ENV['FN_FORMAT']

    if format == 'http-stream'
      listener = ENV['FN_LISTENER']
      if listener == nil || !listener.start_with?('unix:/')
        raise "Missing or invalid socket URL in FN_LISTENER."
      end
      socketFile = listener[5..listener.length]
      tmpFile = socketFile + ".tmp"

      UNIXServer.open(tmpFile) {|serv|
        File.chmod 0666, tmpFile
        puts "Listenign on #{tmpFile}"
        FileUtils.ln_s(File.basename(tmpFile), socketFile)

        while true
          s = serv.accept
          begin
            while true
              req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
              req.parse(s)
              STDERR.puts("got request #{req}")
              resp = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
              resp.status = 200
              resp.body = "hello"
              resp["Content-Type"] = "text/plain"
              resp.chunked = true
              resp.send_response(s)
            end
          rescue EOFError
            s.close
          rescue StandardError => e
            s.close
            STDERR.puts "Error in request handling #{e}"
            raise e
          end
        end
      }

    else
      raise "Format '#{format}' not supported in Ruby FDK."
    end
  end

  def self.single_event(function:, context:, input:)
    send(function, context: context, input: input)
  end
end
