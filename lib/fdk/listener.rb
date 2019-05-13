# frozen_string_literal: true

module FDK
  # Represents the socket that Fn uses to communicate
  # with the FDK (and thence the function)
  # To avoid Fn trying to connect to the socket before
  # it's ready, the Listener creates a socket on (private_socket_path).
  #
  # When the socket is ready to accept connections,
  # the FDK links the private_socket_path to the socket_path.
  #
  # Fn waits for the socket_path to be created and then connects
  class Listener
    attr_reader :url, :private_socket, :fn_logframe_name, :fn_logframe_hdr

    def initialize(url:)
      if url.nil? || !url.start_with?("unix:/")
        raise "Missing or invalid socket URL in FN_LISTENER."
      end

      @fn_logframe_name = ENV["FN_LOGFRAME_NAME"]
      @fn_logframe_hdr = ENV["FN_LOGFRAME_HDR"]

      @url = url
      @private_socket = UNIXServer.open(private_socket_path)
    end

    def socket
      link_socket_file unless @socket
      @socket ||= private_socket
    end

    def link_socket_file
      File.chmod(0o666, private_socket_path)
      FileUtils.ln_s(File.basename(private_socket_path), socket_path)
      FDK.debug "listening on #{private_socket_path}->#{socket_path}"
    end

    def listen(&block)
      raise StandardError("No block given") unless block_given?

      begin
        loop do
          handle_request(fn_block: block)
        end
      rescue StandardError => e
        FDK.log(entry: "Error in request handling #{e}")
        FDK.log(entry: e.backtrace)
      end
    end

    def handle_request(fn_block:)
      local_socket = socket.accept
      req, resp = new_req_resp
      req.parse(local_socket)
      FDK.debug "got request #{req}"
      log_frame_header(req.header)
      fn_block.call(req, resp)
      resp["Connection"] = "close" # we're not using keep alives sadly
      resp.send_response(local_socket)
      FDK.debug "sending resp  #{resp.status}, #{resp.header}"
      local_socket.close
    end

    def new_req_resp
      req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
      resp = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
      [req, resp]
    end

    def socket_path
      @socket_path ||= url[5..url.length]
    end

    def private_socket_path
      socket_path + ".private"
    end

    def log_frame_header(headers)
      return if @fn_logframe_name.nil? || @fn_logframe_hdr.nil?

      k = @fn_logframe_hdr.downcase
      v = headers[k]
      return if v.nil?

      frm = "\n#{@fn_logframe_name}=#{v[0]}\n"
      $stderr.print frm
      $stdout.print frm
    end
  end
end
