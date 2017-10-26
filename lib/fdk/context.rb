module FDK
    class Context

        # fixed
        attr_accessor :app_name, :path, :format, :memory, :type, :config
        # per request
        attr_accessor :request_url, :call_id, :headers, :content_type

        # FN_REQUEST_URL - the full URL for the request (parsing example)
        # FN_APP_NAME - the name of the application that matched this route, eg: myapp
        # FN_PATH - the matched route, eg: /hello
        # FN_METHOD - the HTTP method for the request, eg: GET or POST
        # FN_CALL_ID - a unique ID for each function execution.
        # FN_FORMAT - a string representing one of the function formats, currently either default or http. Default is default.
        # FN_MEMORY - a number representing the amount of memory available to the call, in MB
        # FN_TYPE - the type for this call, currently 'sync' or 'async'
        # FN_HEADER_$X - the HTTP headers that were set for this request. Replace $X with the upper cased name of the header and replace dashes in the header with underscores.
        # $X - any configuration values you've set for the Application or the Route. Replace X with the upper cased name of the config variable you set. Ex: minio_secret=secret will be exposed via MINIO_SECRET env var.
        # FN_PARAM_$Y

        def initialize()
            @config = {}
            @headers = {}
            ENV.each_pair do |k,v|
                STDERR.puts "#{k}: #{v}"
                if k.start_with? "FN_"
                    k3 = k[3..-1]
                    if k3.start_with? "HEADER_"
                        STDERR.puts "header: #{k3}"
                        k4 = k3[7..-1]
                        STDERR.puts k4
                        @headers[k4] = v
                        if k4.downcase == "content_type"
                            @content_type = v
                        end
                        next
                    end
                    k2 = k3.downcase
                    self.instance_variable_set("@#{k2}".to_sym, v)                    
                    next
                end
                @config[k] = v
            end
        end

        def self.newFromJSON(payload)
            c = Context.new
            c.request_url = payload['request_url']
            c.call_id = payload['call_id']
            ct = payload['headers']['Content-Type']
            if ct != nil && ct.length > 0
                # man, let's make these headers single values...
                c.content_type = ct[0]
            end
            return c
        end

        # This returns the per request data, such as headers, request_id, etc
        def [](key)
            return config[key]
        end
    end
end
