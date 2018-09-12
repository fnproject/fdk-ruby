require 'fdk'

def myfunction(context:, input:)
  STDERR.puts("Hoot hoot")
  STDERR.puts("format: " + ENV['FN_FORMAT'])
  input_value = input.respond_to?(:fetch) ? input.fetch('name') : input
  name = input_value.to_s.strip.empty? ? 'World' : input_value
  { message: "Hello #{name}!" }
end

FDK.handle(:myfunction)
