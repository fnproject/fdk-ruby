require 'webrick'
require 'fileutils'
require 'json'
require 'set'

# Looks for call(context, input) function
# Executes it with input
# Responds with output
module FDK
  @filter_headers = Set['content-length', 'te', 'transfer-encoding', 'upgrade', 'trailer']

  def self.handle(function)
    debug = ENV['FDK_DEBUG'] == 'true'
    format = ENV['FN_FORMAT']

    if format == 'http-stream'
      listener = ENV['FN_LISTENER']
      if listener == nil || !listener.start_with?('unix:/')
        raise "Missing or invalid socket URL in FN_LISTENER."
      end
      socket_file = listener[5..listener.length]
      tmp_file = socket_file + ".tmp"

      UNIXServer.open(tmp_file) {|serv|
        File.chmod 0666, tmp_file
        puts "listening on #{tmp_file}->#{socket_file}"
        FileUtils.ln_s(File.basename(tmp_file), socket_file)

        while true
          s = serv.accept
          begin
            begin
              req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
              req.parse s
              STDERR.puts("got request #{req}")
              resp = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
              resp.status = 200
              self.handle_function(function, req, resp)
              resp.send_response s
              STDERR.puts("sending resp  #{resp.status}, #{resp.header}")

            end while req.keep_alive?

          rescue StandardError => e
            STDERR.puts "Error in request handling #{e}"
          end
          s.close
        end
      }

    else
      raise "Format '#{format}' not supported in Ruby FDK."
    end
  end

  def self.set_error(resp, error)
    STDERR.puts "Error in function #{error}"

    resp['content-type'] = 'application/json'
    resp.status = 502
    resp.body = {:message => "An error occurred in the function", :detail => error.to_s}.to_json

  end

  def self.handle_function(function, req, resp)

    headers = {}
    req.header.map {|k, v|
      unless @filter_headers.include? k
        headers[k] = v
      end
    }


    headers_out_hash = {}
    headers_out = FDK::OutHeaders.new(headers_out_hash, nil)

    context = FDK::Context.new(headers, headers_out)

    # TODO be smarter about input handling - accept binary etc.
    input = req.body.to_s

    begin
      input = JSON.parse input
      rv = if function.respond_to? :call
             function.call(context: context, input: input)
           else
             send(function, context: context, input: input)
           end
    rescue StandardError => e
      set_error(resp, e)
      return # why the return?
    end
    resp.status = 200
    headers_out_hash.map do |k, v|
      resp[k] = v unless @filter_headers.include? k
    end

    # TODO: gimme a bit me flexibility on response handling
    # binary, streams etc
    if !rv.nil? && rv.respond_to?('to_json')
      resp.body = rv.to_json
      resp['content-type'] = 'application/json'
    else
      resp.body = rv.to_s
    end
  end
end
