require 'date'

module FDK

  # Config looks up values in the env vars
  class Config
    def [](key)
      ENV[key.upcase]
    end
  end


  class OutHeaders

    def initialize(h, key_fn)
      @headers = h
      @key_fn = key_fn
    end

    def [](key)
      if @key_fn
        key = @key_fn.call(key)
      end
      h = @headers[key.downcase]
      if h != nil
        return h[0]
      end
      nil
    end

    def []=(key, value)
      if @key_fn
        key = @key_fn.call(key)
      end

      if value.respond_to? 'each'
        h = []
        value.each {|x| h.push(x.to_s)}
        @headers[key.downcase] = v
      else
        @headers[key.downcase] = [value.to_s]
      end
    end

    def add(key, *value)
      if value.length > 0
        @headers[key.downcase] = value.to_s
      else
        delete(key)
      end
    end

    def delete(key)
      if @key_fn
        key = @key_fn.call(key)
      end
      @headers.delete key.to_lower
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
      @headers = headers
      @response_headers = OutHeaders.new(headers_out, nil)
    end


    def config
      @config ||= Config.new
    end

    def call_id
      @headers['fn-call-id']
    end


    def app_id
      @config['FN_APP_ID']
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
      HTTPContext.new(@headers, OutHeaders.new(@response_headers, lambda do |v|
        'fn-http-h-' + v
      end))
    end
  end


  class HTTPContext
    def initialize(headers_in, headers_out)
      @context = ctx
      headers_in.map {|k, v|
        if k.downcase.start_with?('fn-http-h-')
          newKey = k['fn-http-h-'.length..k.length]
          headers[newKey] = v
        end
      }
      @headers = headers

      @headers_out = headers_out
    end

    def headers
      @headers
    end

    def request_url
      @context.headers['fn-http-request-url']
    end

    def method
      @context.headers['fn-http-method']
    end


    def status_code=(val)
      @context.response_headers['fn-http-status'] = val.to_i
    end

  end
end

