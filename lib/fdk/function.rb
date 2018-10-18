module FDK
  # Function represents a target function or lambda
  class Function
    attr_reader :format, :function
    def initialize(function:, format:)
      raise "'#{format}' not supported in Ruby FDK." unless format == "http-stream"

      @format = format
      @function = function
    end

    def call(request:, response:)
      Call.invoke(target: function, request: request, response: response)
    end
  end
end
