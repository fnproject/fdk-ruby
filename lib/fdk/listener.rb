# frozen_string_literal: true

#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
      "#{socket_path}.private"
    end

    def log_frame_header(headers)
      return unless logframe_vars_exist

      k = @fn_logframe_hdr.downcase
      v = headers[k]
      return if v.nil? || v.empty?

      frm = "\n#{@fn_logframe_name}=#{v[0]}\n"
      $stderr.print frm
      $stderr.flush
      $stdout.print frm
      $stdout.flush
    end

    def logframe_vars_exist
      return false if @fn_logframe_name.nil? || @fn_logframe_name.empty? ||
                      @fn_logframe_hdr.nil? || @fn_logframe_hdr.empty?

      true
    end
  end
end
