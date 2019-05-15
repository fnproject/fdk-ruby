# frozen_string_literal: true

require "date"

module FDK
  # Config looks up values in the env vars
  class Config
    def [](key)
      ENV[key.upcase]
    end
  end

  # Represents inbound HTTP headers
  class InHeaders
    def initialize(headers, key_fn)
      @headers = headers
      @key_fn = key_fn
    end

    def header_key(key)
      key = @key_fn.call(key) if @key_fn
      key.downcase
    end

    def [](key)
      h = @headers[header_key(key)]
      return h[0] unless h.nil?
    end

    def each(&block)
      @headers.each(&block)
    end
  end

  # Represents outbound HTTP headers
  class OutHeaders < InHeaders
    def initialize(headers, key_in_fn)
      super(headers, key_in_fn)
    end

    def []=(key, value)
      if value.is_a? Array
        h = []
        value.each { |x| h.push(x.to_s) }
        @headers[header_key(key)] = h
      else
        @headers[header_key(key)] = [value.to_s]
      end
    end

    def delete(key)
      @headers.delete header_key(key)
    end
  end

  # Represents the Fn context for a function execution
  class Context
    # FN_APP_ID -the ID of the application that this function is a member of.
    # FN_APP_NAME - the name of the application.
    # FN_CALL_ID - a unique ID for each function execution.
    # FN_FN_ID - the ID of this function
    # FN_MEMORY - a number representing the amount of memory available to the call, in MB
    # $X - any configuration values you've set for the Application.
    #   Replace X with the upper cased name of the config variable you set.
    #   e.g. minio_secret=secret will be exposed via MINIO_SECRET env var.

    attr_reader :headers
    attr_reader :response_headers

    def initialize(headers_in, headers_out)
      @headers = headers_in
      @response_headers = headers_out
      @config ||= Config.new
    end

    def call_id
      @headers["fn-call-id"]
    end

    def app_id
      @config["FN_APP_ID"]
    end

    def fn_id
      @config["FN_FN_ID"]
    end

    def deadline
      DateTime.iso8601(@headers["fn-deadline"])
    end

    def memory
      @config["FN_MEMORY"].to_i
    end

    def content_type
      @headers["content-type"]
    end

    def http_context
      HTTPContext.new(self)
    end
  end

  # Represents the context data (inbound && outbound)
  # for the execution passed as HTTP headers
  class HTTPContext
    attr_reader :headers
    attr_reader :response_headers

    def initialize(ctx)
      fn_http_h_ = "fn-http-h-"
      @ctx = ctx
      http_headers = {}
      ctx.headers.each do |k, v|
        http_headers[k.sub(fn_http_h_, "")] = v if k.downcase.start_with?(fn_http_h_)
      end
      @headers = InHeaders.new(http_headers, nil)
      @response_headers = OutHeaders.new(ctx.response_headers, ->(s) { fn_http_h_ + s })
    end

    def request_url
      @ctx.headers["fn-http-request-url"]
    end

    def method
      @ctx.headers["fn-http-method"]
    end

    def status_code=(val)
      @ctx.response_headers["fn-http-status"] = val.to_i
    end
  end
end
