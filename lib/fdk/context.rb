module FDK

  # Config looks up values in the env vars
  class Config
    def [](key)
      ENV[key.upcase]
    end
  end

  class Context

    # TODO: Rethink FN_PATH, if it's a reference to the route, maybe it should be FN_ROUTE? eg: if it's a dynamic path, this env var would
    #    show the route's path (ie: route identifier), eg: /users/:name, not the actual path.

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

    # CloudEvent format: https://github.com/cloudevents/spec/blob/master/serialization.md#json

    attr_reader :event

    def initialize(event)
      @event = event
    end

    # If it's a CNCF CloudEvent
    def cloud_event?
      return ENV['FN_FORMAT'] == "cloudevent"
    end

    def config
      @config ||= Config.new
    end

    def call_id
      if cloud_event?
        return event['eventID']
      end
      event['call_id']
    end

    def content_type
      if cloud_event?
        return event['contentType']
      end
      event['content_type']
    end

    def protocol
      if cloud_event?
        return event['extensions']['protocol']
      end
      event['protocol']
    end
  end
end
