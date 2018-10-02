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

  def simple_req(client, body, headers)
    req = Net::HTTP::Post.new("/call")
    headers.each {|k, v|
      req[k] = v
    }
    req.body = body
    client.request(req)
  end

  def simple_fdk_call (handler)

    ENV['FN_FORMAT'] = 'http-stream'
    Dir.mktmpdir {|dir|
      sockfile = "#{dir}/test.sock"
      ENV['FN_LISTENER'] = "unix:#{sockfile}"
      thr = Thread.new {FDK.handle(handler)}
      wait_for_socket sockfile
      client = NetX::HTTPUnix.new('unix://' + sockfile)
      yield client

      thr.kill
      thr.join
    }
  end

  def test_handle_simple_request()

    simple_fdk_call (lambda {|context:, input:| "#{input} world"}) {|client|
      resp = simple_req client, "hello", {'content-type' => 'text/plain'}
      puts resp.body
      assert_equal 200, resp.code.to_i
      assert_equal "\"hello world\"", resp.body
      assert_equal "application/json", resp['content-type']
    }


  end


  def parses_json_input()
    got_input = nil

    simple_fdk_call (Proc.new {|context:, input:| got_input = input; nil}) {|client|
      resp = simple_req client, '{"message":"hello"}', {}
      assert_equal 200, resp.code.to_i
      assert_equal "hello", got_input['message']
    }

  end

end