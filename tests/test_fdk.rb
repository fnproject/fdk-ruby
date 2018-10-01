require_relative "../lib/fdk"
require "test/unit"
require "tmpdir"
require 'net_http_unix'

def testfn(context:, input:)

end

class TestFdk < Test::Unit::TestCase

  def test_require_format()
    ENV['FN_FORMAT'] = ''
    ENV['FN_LISTENER'] = 'unix:/tmp/foo.sock'


    begin
      FDK.handle(:testfn)
      assert(false, 'should have failed')
    rescue
    end

  end

  def test_require_listener()
    ENV['FN_FORMAT'] = 'http-stream'

    begin
      FDK.handle(:testfn)
      assert(false, 'should have failed')
    rescue
    end
  end

  def wait_for_socket(file)
    for i in 0..100
      puts "waiting for #{file}"
      if File.exists? file
        return
      else
        sleep 0.1
      end
    end
    raise "No file found after 10 seconds"
  end

  def test_handle_simple_request()
    ENV['FN_FORMAT'] = 'http-stream'
    Dir.mktmpdir {|dir|
      sockfile = "#{dir}/test.sock"
      ENV['FN_LISTENER'] = "unix:#{sockfile}"
      thr = Thread.new {FDK.handle(:testfn)}
      wait_for_socket sockfile

      req = Net::HTTP::Post.new("/call")
      req.body = "hello"
      client = NetX::HTTPUnix.new('unix://' + sockfile)

      resp = client.request(req)
      puts resp.body

      thr.kill
      thr.join
    }

  end

end