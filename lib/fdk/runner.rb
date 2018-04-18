# Looks for call(context, input) function
# Executes it with input
# Responds with output

require 'json'
require 'yajl'

module FDK
  def self.handle(func)
    format = ENV['FN_FORMAT']
    if format == 'json'
      parser = Yajl::Parser.new

      parser.on_parse_complete = lambda do |payload|
        context = Context.new(payload)
        body = payload['body']
        if context.content_type == 'application/json' && body != ''
          body = Yajl::Parser.parse(body)
        end
        se = FDK.single_event(function: func, context: context, input: body)
        response = {
          headers: {
            'Content-Type' => 'application/json'
          },
          'status_code' => 200,
          body: se.to_json
        }
        STDOUT.puts response.to_json
        STDOUT.puts
        STDOUT.flush
      end

      STDIN.each_line { |line| parser.parse_chunk(line) }

    elsif format == 'default'
      payload = {}
      payload['call_id'] = ENV['FN_CALL_ID']
      payload['protocol'] = {
        'type' => 'http',
        'request_url' => ENV['FN_REQUEST_URL']
      }
      c = Context.new(payload)
      puts FDK.single_event(function: func, context: c, input: STDIN.read).to_json
    else
      raise "Format '#{format}' not supported in Ruby FDK."
    end
  end

  def self.single_event(function:, context:, input:)
    send function, context: context, input: input
  end
end
