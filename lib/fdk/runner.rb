require "webrick"
require "fileutils"
require "json"
require "set"

# Looks for call(context, input) function
# Executes it with input
# Responds with output
module FDK
  @dbg = ENV["FDK_DEBUG"]

  def self.debug(msg)
    STDERR.puts(msg) if @dbg
  end

  def self.handle(target:)
    func = Function.new(function: target, format: ENV["FN_FORMAT"])
    Listener.new(url: ENV["FN_LISTENER"]).listen do |req, resp|
      func.call(request: req, response: resp)
    end
  end
end
