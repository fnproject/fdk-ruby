# Ruby Function Developer Kit (FDK)

This provides a Ruby framework for deleloping functions for us with [Fn](https://fnproject.github.io).

## Function Handler

To use this FDK, you simply need to require this gem.

```ruby
require 'fdk`
```

Then create a function with with the following syntax:

```ruby
def myfunc(context, input) 
    # Do some work here
    return output
end
```

* context - provides runtime information for your function, such as configuration values, headers, etc.
* input – This parameter is a string containing body of the request.
* output - is where you can return data back to the caller. Whatever you return will be sent back to the caller. If `async`, this value is ignored.
  * Default output format should be in JSON, as Content-Type header will be `application/json` by default. You can be more flexible if you create and return
    an FDK::Response object instead of a string.

Then simply pass that function to the FDK:

```ruby
FDK.call(myfunc)
```

## Full Example

```ruby
require 'fdk'

def myhandler(context, input)
    STDERR.puts "request_url: " + context.protocol['request_url']
    STDERR.puts "call_id: " + context.call_id
    STDERR.puts "input: " + input.to_s
    return {message: "Hello " + input['name'].to_s + "!"}
end

FDK.handle(:myhandler)
```

## Running the example that is in the root directory of this repo

```sh
echo '{"name":"coolio"}' | fn run
```

```sh
fn deploy --app myapp --local && echo '{"name":"coolio"}' | fn call myapp /fdk-ruby
```

Change to hot:

Update func.yaml: `format: json`

```sh
fn deploy --app myapp --local && echo '{"name":"coolio"}' | fn call myapp /fdk-ruby
```

## Compare cold and hot

Run

```sh
ruby loop.rb
```
