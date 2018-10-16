module FDK
  # Call represents a call to the target function or lambda
  class Call
    FILTER_HEADERS = ["content-length", "te", "transfer-encoding",
                      "upgrade", "trailer"].freeze

    attr_reader :request, :target, :response
    attr_accessor :error

    def self.invoke(target:, request:, response:)
      call = Call.new(target: target, request: request, response: response)
      call.invoke_target
    end

    def initialize(target:, request:, response:)
      @target = target
      @request = request
      @response = response
    end

    def context
      @context ||= FDK::Context.new(headers_in, headers_out)
    end

    def input
      @input ||= ParsedInput.new(raw_input: request.body.to_s)
    end

    # TODO: Lose this
    def headers_out_hash
      @headers_out_hash ||= {}
    end

    def headers_out
      @headers_out ||= FDK::OutHeaders.new(headers_out_hash, nil)
    end

    def headers_in
      @headers_in ||= FDK::InHeaders.new(filtered_request_header, nil)
    end

    def filtered_request_header
      filter_out_headers(unfiltered: request.header)
    end

    def filtered_response_header
      filter_out_headers(unfiltered: headers_out_hash)
    end

    def filter_out_headers(unfiltered:)
      unfiltered.reject { |k| FILTER_HEADERS.include? k }
    end

    def invoke_target
      retval = target.respond_to?(:call) ? target_call : target_send
      good_response
      format_response_body(fn_return: retval)
    rescue StandardError => e
      error_response(error: e)
    end

    def format_response_body(fn_return:)
      if fn_return.respond_to?(:to_json)
        response.body = fn_return.to_json
        response["content-type"] = "application/json" unless response["content-type"]
      else
        response.body = fn_return.to_s
      end
    end

    def target_call
      target.call(context: context, input: input.parsed)
    end

    def target_send
      send(target, context: context, input: input.parsed)
    end

    def good_response
      response.status = 200
      filtered_response_header.each { |k, v| response[k] = v.join(",") }
    end

    def error_response(error:)
      response["content-type"] = "application/json"
      response.status = 502
      response.body = { message: "An error occurred in the function",
                        detail: error.to_s }.to_json
    end

    private :target_call, :target_send
  end
end
