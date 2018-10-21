module FDK
  # Function represents a function function or lambda
  class Function
    attr_reader :format, :function
    def initialize(function:, format:)
      raise "'#{format}' not supported in Ruby FDK." unless format == "http-stream"

      @format = format
      @function = function
    end

    def as_lambda
      return function if function.respond_to?(:call)

      ->(context:, input:) { send(function, context: context, input: input) }
    end

    def call(request:, response:)
      Call.new(request: request, response: response).process(&as_lambda)
    end
  end
end
