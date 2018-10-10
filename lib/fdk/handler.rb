module FDK
  class Call
    FILTER_HEADERS = ["content-length", "te", "transfer-encoding",
                      "upgrade", "trailer"].freeze

    def initialize(target:, request:, response:)
      @target = target
      @request = request
      @response = response
    end

    def context
      @context ||= FDK::Context.new(headers_in, headers_out)
    end

    def headers_out
      @headers_out ||= FDK::OutHeaders.new({}, nil)
    end

    def headers_in
      @headers_in ||= FDK::InHeaders.new(filtered_request_header, nil)
    end

    def filtered_request_header
      @request.header.reject { |k| FILTER_HEADERS.include? k }
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
