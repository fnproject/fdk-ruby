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

## Example

```ruby
require 'fdk'

def myfunc(context, input)
    return {message: "Hello World!"}
end

FDK.handle(:myfunc)

def call(context, input) 
    # Do some work here
    return "Hello " + input + "!"
end
```

## Example in root dir

```sh
echo '{"name":"coolio"}' | fn run
```

```sh
fn deploy --app myapp --local
echo '{"name":"coolio"}' | fn call myapp /fdk-ruby
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
