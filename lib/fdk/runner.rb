# Looks for call(context, input) function
# Executes it with input
# Responds with output

require 'json'

module FDK
  def self.handle(func)
    format = ENV['FN_FORMAT']
    if format == 'json'
      payload = JSON.parse(STDIN.read)
      ctx = Context.new(payload)
      body = payload['body']
      if ctx.content_type == 'application/json' && body != ''
        body = JSON.parse(body)
      end
      # TODO: begin/rescue so we can respond with proper error response and code
      se = FDK.single_event(func, ctx, body)
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
    elsif format == 'default'
      body = STDIN.read
      payload = {}
      payload['call_id'] = ENV['FN_CALL_ID']
      payload['content_type'] = ENV['FN_HEADER_Content_Type']
      payload['protocol'] = {
        'type' => 'http',
        'request_url' => ENV['FN_REQUEST_URL']
      }
      c = Context.new(payload)
      body = JSON.parse(body) if c.content_type == 'application/json'
      puts FDK.single_event(func, c, body).to_json
    else
      raise "Format '#{format}' not supported in Ruby FDK."
    end
  end

  def self.single_event(func, context, input)
    send func, context, input
  end
end
