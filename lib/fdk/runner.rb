require "webrick"
require "fileutils"
require "json"
require "set"
require_relative "./call"
require_relative "./support_classes"

# Looks for call(context, input) function
# Executes it with input
# Responds with output
module FDK
  @filter_headers = Set["content-length", "te", "transfer-encoding",
                        "upgrade", "trailer"]

  def self.check_format
    f = ENV["FN_FORMAT"]
    raise "'#{f}' not supported in Ruby FDK." unless f == "http-stream"

    f
  end
  private_class_method :check_format

  def self.listener
    l = ENV["FN_LISTENER"]
    if l.nil? || !l.start_with?("unix:/")
      raise "Missing or invalid socket URL in FN_LISTENER."
    end

    l
  end
  private_class_method :listener

  @dbg = ENV["FDK_DEBUG"]

  def self.debug(msg)
    STDERR.puts(msg) if @dbg
  end
  private_class_method :debug

  def self.handle(target:)
    # To avoid Fn trying to connect to the socket before
    # it's ready, the FDK creates a socket on (tmp_file).
    #
    # When the socket is ready to accept connections,
    # the FDK links the tmp_file to the socket_file.
    #
    # Fn waits for the socket_file to be created and then connects
    check_format
    l = listener
    socket_file = l[5..l.length]
    tmp_file = socket_file + ".tmp"

    debug tmp_file
    debug socket_file
    UNIXServer.open(tmp_file) do |serv|
      File.chmod(0o666, tmp_file)
      debug "listening on #{tmp_file}->#{socket_file}"
      FileUtils.ln_s(File.basename(tmp_file), socket_file)

      loop do
        s = serv.accept
        begin
          loop do
            req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
            req.parse s
            debug "got request #{req}"
            resp = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
            resp.status = 200
            handle_call(target, req, resp)
            resp.send_response s
            debug "sending resp  #{resp.status}, #{resp.header}"
            break unless req.keep_alive?
          end
        rescue StandardError => e
          STDERR.puts "Error in request handling #{e}"
          STDERR.puts e.backtrace
        end
        s.close
      end
    end
  end

  def self.handle_call(target, req, resp)
    my_call = Call.new(target: target, request: req, response: resp)
    my_call.invoke_target
  end
end
