require "webrick"
require "fileutils"
require "json"
require "set"

# Looks for call(context, input) function
# Executes it with input
# Responds with output
module FDK
  @filter_headers = Set["content-length", "te", "transfer-encoding",
                        "upgrade", "trailer"]

  def self.format
    f = (@format = ENV["FN_FORMAT"])
    raise "'#{f}' not supported in Ruby FDK." unless f == "http-stream"

    @format
  end

  def self.listener
    l = (@listener ||= ENV["FN_LISTENER"])
    if l.nil? || !l.start_with?("unix:/")
      raise "Missing or invalid socket URL in FN_LISTENER."
    end

    @listener
  end

  def self.handle(function)
    # To avoid Fn trying to connect to the socket before
    # it's ready, the FDK creates a socket on (tmp_file).
    #
    # When the socket is ready to accept connections,
    # the FDK links the tmp_file to the socket_file.
    #
    # Fn waits for the socket_file to be created and then connects
    socket_file = listener[5..listener.length]
    tmp_file = socket_file + ".tmp"

    UNIXServer.open(tmp_file) do |serv|
      File.chmod(0o666, tmp_file)
      puts "listening on #{tmp_file}->#{socket_file}"
      FileUtils.ln_s(File.basename(tmp_file), socket_file)

      loop do
        s = serv.accept
        begin
          loop do
            req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
            req.parse s
            STDERR.puts("got request #{req}")
            resp = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
            resp.status = 200
            handle_function(function, req, resp)
            resp.send_response s
            STDERR.puts("sending resp  #{resp.status}, #{resp.header}")
            break unless req.keep_alive?
          end
        rescue StandardError => e
          STDERR.puts "Error in request handling #{e}"
        end
        s.close
      end
    end
  end

  def self.debug
    @debug ||= ENV["FDK_DEBUG"]
  end

  def self.set_error(resp, error)
    STDERR.puts "Error in function #{error}"

    resp["content-type"] = "application/json"
    resp.status = 502
    resp.body = { message: "An error occurred in the function",
                  detail: error.to_s }.to_json
  end

  def self.handle_function(function, req, resp)
    headers = {}
    req.header.map do |k, v|
      headers[k] = v unless @filter_headers.include? k
    end

    headers_out_hash = {}
    headers_out = FDK::OutHeaders.new(headers_out_hash, nil)

    context = FDK::Context.new(headers, headers_out)

    input = ParsedInput.new(raw_input: req.body.to_s)
    begin
      rv = if function.respond_to? :call
             function.call(context: context, input: input.parsed)
           else
             send(function, context: context, input: input.parsed)
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
    if !rv.nil? && rv.respond_to?("to_json")
      resp.body = rv.to_json
      resp["content-type"] = "application/json"
    else
      resp.body = rv.to_s
    end
  end

  # Stores raw input and can parse it as
  # JSON (add extra formats as required)
  class ParsedInput
    attr_reader :raw

    def initialize(raw_input:)
      @raw = raw_input
    end

    def as_json
      @json ||= JSON.parse(raw)
    rescue JSON::ParserError
      @json = false
    end

    def parsed
      as_json || raw
    end
  end
end
