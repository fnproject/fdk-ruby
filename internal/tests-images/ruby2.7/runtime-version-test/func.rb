require 'fdk'

def myfunction(context:, input:)

  # RUBY_VERSION constant holds the ruby interpreter version
  return "ruby#{RUBY_VERSION}"

end

FDK.handle(target: :myfunction)