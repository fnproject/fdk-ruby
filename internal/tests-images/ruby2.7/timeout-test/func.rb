require 'fdk'

def myfunction(context:, input:)
  #sleeping for 6 seconds
    sleep 6
  rescue Exception => e
    FDK.log_error(error: e)
  end

FDK.handle(target: :myfunction)
