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
      socketFile = listener[5..listener.length]
      tmpFile = socketFile + ".tmp"

      UNIXServer.open(tmpFile) {|serv|
        File.chmod 0666, tmpFile
        puts "listening on #{tmpFile}->#{socketFile}"
        FileUtils.ln_s(File.basename(tmpFile), socketFile)

        while true
          s = serv.accept
          begin
            while true
              req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
              req.parse s
              STDERR.puts("got request #{req}")
              resp = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
              resp.status = 200
              self.handle_function(function, req, resp)
              resp.send_response s
              STDERR.puts("sending resp  #{resp.status}, #{resp.header}")

              break unless req.keep_alive?
            end

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

    rescue
    end
    begin
      if function.respond_to? :call
        rv = function.call(context: context, input: input)
      else
        rv = send(function, context: context, input: input)
      end
    rescue => e
      self.set_error(resp, e)
      return
    end
    resp.status = 200
    headers_out_hash.map {|k, v|
      unless @filter_headers.include? k
        resp[k] = v
      end
    }

    #TODO gimme a bit me flexibility on response handling
    # binary, streams etc
    if !rv.nil? && rv.respond_to?('to_json')
      resp.body = rv.to_json
      resp['content-type'] = 'application/json'
    else
      resp.body = rv.to_s
    end


  end
end
