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
  class Function
    attr_reader :format
    def initialize(format:)
      raise "'#{format}' not supported in Ruby FDK." unless format == "http-stream"

      @format = format
    end
  end

  class Listener
    attr_reader :url

    def initialize(url:)
      if url.nil? || !url.start_with?("unix:/")
        raise "Missing or invalid socket URL in FN_LISTENER."
      end

      @url = url
    end

    def socket_file
      @socket_file ||= url[5..url.length]
    end

    def tmp_file
      socket_file + ".tmp"
    end
  end

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
    Function.new(format: ENV["FN_FORMAT"])
    l2 = Listener.new(url: ENV["FN_LISTENER"])
    socket_file = l2.socket_file
    tmp_file = l2.tmp_file

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
            Call.invoke(target: target, request: req, response: resp)
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
end
