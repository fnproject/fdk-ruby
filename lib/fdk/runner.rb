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
    attr_reader :url, :private_socket

    def initialize(url:)
      if url.nil? || !url.start_with?("unix:/")
        raise "Missing or invalid socket URL in FN_LISTENER."
      end

      @url = url
      @private_socket = UNIXServer.open(private_socket_path)
    end

    def socket
      unless @socket
        link_socket_file
      end

      @socket ||= private_socket
    end

    def link_socket_file
      File.chmod(0o666, private_socket_path)
      FileUtils.ln_s(File.basename(private_socket_path), socket_path)
      FDK.debug "listening on #{private_socket_path}->#{socket_path}"
    end

    def listen(target:)
      loop do
        s = socket.accept
        begin
          loop do
            req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
            req.parse s
            FDK.debug "got request #{req}"
            resp = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
            Call.invoke(target: target, request: req, response: resp)
            resp.send_response s
            FDK.debug "sending resp  #{resp.status}, #{resp.header}"
            break unless req.keep_alive?
          end
        rescue StandardError => e
          STDERR.puts "Error in request handling #{e}"
          STDERR.puts e.backtrace
        end
        s.close
      end
    end

    def socket_path
      @socket_path ||= url[5..url.length]
    end

    def private_socket_path
      socket_path + ".private"
    end
  end

  @dbg = ENV["FDK_DEBUG"]

  def self.debug(msg)
    STDERR.puts(msg) if @dbg
  end

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
    l2.listen(target: target)

    # debug tmp_file
    # debug socket_file
    # UNIXServer.open(tmp_file) do |serv|
=begin
    serv = UNIXServer.open(tmp_file) # do |local_serv|
      File.chmod(0o666, tmp_file)
      debug "listening on #{tmp_file}->#{socket_file}"
      FileUtils.ln_s(File.basename(tmp_file), socket_file)
    serv = l2.socket
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
=end
    # end
  end
end
