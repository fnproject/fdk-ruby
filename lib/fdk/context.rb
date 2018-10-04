require 'date'

module FDK

  # Config looks up values in the env vars
  class Config
    def [](key)
      ENV[key.upcase]
    end
  end


  class InHeaders
    def initialize (h, key_fn)
      @headers = h
      @key_fn = key_fn

    end

    def headerKey(key)
      if @key_fn
        key = @key_fn.call(key)
      end
      key.downcase
    end

    def [](key)
      h = @headers[headerKey(key)]
      unless h.nil?
        return h[0]
      end
      nil
    end

    def each (&block)
      @headers.each &block
    end
  end

  class OutHeaders < InHeaders

    def initialize(h, key_in_fn)
      super(h, key_in_fn)
    end


    def []=(key, value)
      if value.is_a? Array
        h = []
        value.each {|x| h.push(x.to_s)}
        @headers[headerKey(key)] = h
      else
        @headers[headerKey(key)] = [value.to_s]
      end
    end

    def delete(key)
      @headers.delete headerKey(key)
    end
  end


  class Context

    # FN_CALL_ID - a unique ID for each function execution.
    # FN_REQUEST_URL - the full URL for the request (parsing example)
    # FN_HEADER_$X - the HTTP headers that were set for this request. Replace $X with the upper cased name of the header and replace dashes in the header with underscores.
    # $X - any configuration values you've set for the Application or the Route. Replace X with the upper cased name of the config variable you set. Ex: minio_secret=secret will be exposed via MINIO_SECRET env var.
    # FN_APP_NAME - the name of the application that matched this route, eg: myapp
    # FN_METHOD - the HTTP method for the request, eg: GET or POST
    # FN_MEMORY - a number representing the amount of memory available to the call, in MB


    attr_reader :headers
    attr_reader :response_headers

    def initialize(headers_in, headers_out)
      @headers = headers_in
      @response_headers = headers_out
      @config ||= Config.new
    end


    def call_id
      @headers['fn-call-id']
    end


    def app_id
      @config['FN_APP_ID']
    end


    def fn_id
      @config['FN_FN_ID']
    end

    def deadline
      DateTime.iso8601(@headers['fn-deadline'])
    end

    def memory
      @config['FN_MEMORY'].to_i
    end

    def content_type
      @headers['content-type']
    end

    def http_context
      HTTPContext.new(self)
    end
  end


  class HTTPContext

    attr_reader :headers
    attr_reader :response_headers

    def initialize(ctx)

      @ctx = ctx


      http_headers = {}
      ctx.headers.each {|k, v|
        if k.downcase.start_with?('fn-http-h-')
          new_key = k['fn-http-h-'.length..k.length]
          http_headers[new_key] = v
        end
      }

      @headers = InHeaders.new(http_headers, nil)
      @response_headers = OutHeaders.new(ctx.response_headers, lambda {|s| 'fn-http-h-' + s})
    end


    def request_url
      @ctx.headers['fn-http-request-url']
    end

    def method
      @ctx.headers['fn-http-method']
    end


    def status_code=(val)
      @ctx.response_headers['fn-http-status'] = val.to_i
    end

  end
end

