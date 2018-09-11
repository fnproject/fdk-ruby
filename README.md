# Ruby Function Developer Kit (FDK)

This provides a Ruby framework for developing functions for use with [Fn](https://fnproject.github.io).

## Function Handler

To use this FDK, you simply need to require this gem.

```ruby
require 'fdk'
```

Then create a function with with the following syntax:

```ruby
def myfunction(context:, input:)
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
FDK.handle(:myfunction)
```

## Hello World Example

```ruby
require 'fdk'

def myfunction(context:, input:)
  input_value = input.respond_to?(:fetch) ? input.fetch('name') : input
  name = input_value.to_s.strip.empty? ? 'World' : input_value
  { message: "Hello #{name}!" }
end

FDK.handle(function: :myfunction)
```

## Examples

See the [examples](examples) folder of this repo for code examples.

### Hello World

Running the [Hello World](examples/hello-ruby) example

```sh
$ echo '{"name":"coolio"}' | fn run
{"message":"Hello coolio!"}
```

You can also specify the format (the default is JSON)

```sh
$ echo '{"name":"coolio"}' | fn run --format json
{"message":"Hello coolio!"}
```

If you want to just pass plain text to the function, specify a format of __default__:

```sh
$ echo 'coolio' | fn run --format default
{"message":"Hello coolio!"}
```

### Deploying the functions to an fn server

With an fn server running (see
[Quickstart](https://github.com/fnproject/fn/blob/master/README.md) if you need instructions):

```sh
fn deploy --app examples --local && echo '{"name":"coolio"}' | fn call examples /hello-ruby
```

Change to hot:

Update func.yaml: `format: json`

```sh
fn deploy --app examples --local && echo '{"name":"coolio"}' | fn call examples /hello-ruby
```

### Compare cold and hot functions

Run [loop.rb](examples/loop.rb)

```sh
ruby loop.rb
```
