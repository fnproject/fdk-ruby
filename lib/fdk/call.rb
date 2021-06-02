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
  # Call represents a call to the target function or lambda
  class Call
    FILTER_HEADERS = %w[content-length te transfer-encoding upgrade trailer].freeze

    attr_reader :request, :response
    attr_accessor :error

    def initialize(request:, response:)
      @request = request
      @response = response
    end

    def context
      @context ||= FDK::Context.new(headers_in, headers_out)
    end

    def input
      @input ||= ParsedInput.new(raw_input: request.body.to_s)
    end

    def headers_out
      @headers_out ||= FDK::OutHeaders.new({ "Fn-Fdk-Version" =>
                                             ["fdk-ruby/#{FDK::VERSION}"] }, nil)
    end

    def headers_in
      @headers_in ||= FDK::InHeaders.new(filtered_request_header, nil)
    end

    def filtered_request_header
      request.header.reject { |k| FILTER_HEADERS.include? k }
    end

    def process
      format_response_body(fn_return: yield(context: context, input: input.parsed))
      good_response
    rescue StandardError => e
      FDK.log_error(error: e)
      error_response(error: e)
    end

    def format_response_body(fn_return:)
      return response.body = fn_return.to_s unless fn_return.respond_to?(:to_json)

      response.body = fn_return.to_json
      response["Content-Type"] = "application/json" unless response["Content-Type"]
    end

    def good_response
      response.status = 200
      headers_out.each { |k, v| response[k] = v.join(",") }
    end

    def error_response(error:)
      response["Content-Type"] = "application/json"
      response.status = 502
      response.body = { message: "An error occurred in the function",
                        detail: error.to_s }.to_json
    end
  end
end
