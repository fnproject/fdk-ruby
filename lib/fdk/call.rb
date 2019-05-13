# frozen_string_literal: true

module FDK
  # Call represents a call to the target function or lambda
  class Call
    FILTER_HEADERS = ["content-length", "te", "transfer-encoding",
                      "upgrade", "trailer"].freeze

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
      @headers_out ||= FDK::OutHeaders.new({}, nil)
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
      response["content-type"] = "application/json" unless response["content-type"]
    end

    def good_response
      response.status = 200
      headers_out.each { |k, v| response[k] = v.join(",") }
    end

    def error_response(error:)
      response["content-type"] = "application/json"
      response.status = 502
      response.body = { message: "An error occurred in the function",
                        detail: error.to_s }.to_json
    end
  end
end
