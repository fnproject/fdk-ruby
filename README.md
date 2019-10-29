# Function Developer Kit for Ruby
The Function Developer Kit for Ruby (FDK for Ruby) provides a Ruby framework for developing functions for use with [Fn](https://fnproject.github.io).

[![CircleCI](https://circleci.com/gh/fnproject/fdk-ruby.svg?style=svg)](https://circleci.com/gh/fnproject/fdk-ruby)

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
FDK.handle(target: :myfunction)
```

## Examples

See the [examples](examples) folder of this repo for code examples.

### Hello World Example

In the [hello-ruby](examples/hello-ruby) folder there is a traditional "Hello  World" example.  The code is found in [func.rb](examples/hello-ruby/func.rb):

```ruby
require 'fdk'

def myfunction(context:, input:)
  input_value = input.respond_to?(:fetch) ? input.fetch('name') : input
  name = input_value.to_s.strip.empty? ? 'World' : input_value
  { message: "Hello #{name}!" }
end

FDK.handle(target: :myfunction)
```

## Deploying functions

To use a function we need to deploy it to an fn server.

In fn an _app_ consist of one or more functions and each function is
deployed as part of an app.

We're going to deploy the hello world example as part of the app
`examples`.

With an fn server running (see
[Quickstart](https://github.com/fnproject/fn/blob/master/README.md) if you need instructions):

`cd` to the [hello-ruby](examples/hello-ruby) folder and run:

```sh
fn deploy --app examples --local
```

The `--app examples` option tells fn to deploy the function as part of
the _app_ named _examples_.

The `--local` option tells fn not to push the function image to Docker
Hub.

## Invoking functions
Once we have deployed a function we can invoke it using `fn invoke`.

Running the [Hello World](examples/hello-ruby) example:
```sh
$ fn invoke examples hello
{"message":"Hello World!"}
```
To get a more personal message, send a name in a JSON format and set the
`content-type 'application/json'`:
```
echo '{"name":"Joe"}' | fn invoke examples hello --content-type 'application/json'
{"message":"Hello Joe!"}
```

