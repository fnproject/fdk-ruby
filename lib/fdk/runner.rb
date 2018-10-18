require "webrick"
require "fileutils"
require "json"
require "set"

# Looks for call(context, input) function
# Executes it with input
# Responds with output
module FDK
  class Function
    attr_reader :format
    def initialize(format:)
      raise "'#{format}' not supported in Ruby FDK." unless format == "http-stream"

      @format = format
    end
  end

  @dbg = ENV["FDK_DEBUG"]

  def self.debug(msg)
    STDERR.puts(msg) if @dbg
  end

  def self.handle(target:)
    Function.new(format: ENV["FN_FORMAT"])
    Listener.new(url: ENV["FN_LISTENER"]).listen { |req, resp| Call.invoke(target: target, request: req, response: resp) }
  end
end
