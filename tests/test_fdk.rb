#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../lib/fdk"
require "test/unit"
require "tmpdir"
require "net_http_unix"
require "json"

def testfn(context:, input:)
  "Hello world from method"
end

class TestFdk < Test::Unit::TestCase

  def test_require_format

    Dir.mktmpdir {|dir|
      sockfile = "#{dir}/test.sock"
      with_env({
                       "FN_FORMAT" => "",
                       "FN_LISTENER" => "unix:#{sockfile}",
               }) {
        begin
          FDK.handle(target: :testfn)
          assert(false, " should have failed ")
        rescue StandardError => e
          puts e

        end
      }
    }

  end

  def test_require_listener
    with_env({
                     "FN_FORMAT" => "http-stream",
             }) {
      begin
        FDK.handle(target: :testfn)
        assert(false, " should have failed ")
      rescue
      end
    }

  end


  def test_handle_simple_request()
    run_fdk (lambda {|context:, input:| "#{input} world"}) {|client|
      resp = simple_req client, "hello", {"Content-Type" => "text/plain"}
      assert_equal 200, resp.code.to_i
      assert_equal "\"hello world\"", resp.body
      assert_equal "application/json", resp["Content-Type"]
    }
  end


  def test_function_raises_error()

    run_fdk (lambda {|context:, input:| raise "something went wrong"}) {|client|
      resp = simple_req client
      assert_equal 502, resp.code.to_i
      assert_equal "application/json", resp["Content-Type"]

      err = JSON.parse resp.body
      assert_equal "An error occurred in the function", err["message"]
      assert_equal "something went wrong", err["detail"]

    }


  end


  def test_accepts_method()

    run_fdk (:testfn) {|client|
      resp = simple_req client, "hello", {"Content-Type" => "text/plain"}
      assert_equal 200, resp.code.to_i
      assert_equal "\"Hello world from method\"", resp.body
      assert_equal "application/json", resp["Content-Type"]
    }


  end


  def test_parses_json_input()
    got_input = nil

    run_fdk (Proc.new {|context:, input:| got_input = input; nil}) {|client|
      resp = simple_req client, '{"message":"hello"}', {}

      assert_equal 200, resp.code.to_i
      assert_equal "hello", got_input["message"]
    }

  end


  def test_populates_context
    got_ctx = nil
    with_env ({"FN_MEMORY" => "128", "FN_APP_ID" => "AppID", "FN_FN_ID" => "FnId", "MyConfig" => "foo"}) {
      run_fdk (Proc.new {|context:, input:| got_ctx = context; nil}) {|client|
        resp = simple_req client, '{"message":"hello"}',
                          {"Fn-Deadline" => ["2018-10-04T13:20:32.665Z"],
                           "Fn-Call-Id" => ["call-ID"],
                           "Content-Type" => ["foo/bar"],
                           "My-Header" => ["foo"]
                          }

        assert_equal 200, resp.code.to_i
        assert_equal DateTime.parse("2018-10-04T13:20:32.665Z"), got_ctx.deadline
        assert_equal "call-ID", got_ctx.call_id
        # annoyingly Net::HTTP collapses request headers so we can"t easily test multi-valued headers here (they do work though)
        assert_equal "foo", got_ctx.headers["My-header"]
        assert_equal 128, got_ctx.memory
        assert_equal "AppID", got_ctx.app_id
        assert_equal "FnId", got_ctx.fn_id
        assert_equal "foo/bar", got_ctx.content_type
      }
    }
  end

  def test_sets_resp_context
    run_fdk (Proc.new {|context:, input:|
      context.response_headers["Content-Type"] = "Foo/bar"
      context.response_headers["foo"] = ["bar", "baz"]
      context.response_headers["bing"] = "bob"
      context.response_headers["bob"] = {"a" => "b"}
      context.response_headers.delete("bing")
      "content"
    }) {|client|

      resp = simple_req client
      assert_equal 200, resp.code.to_i
      assert_equal "bar,baz", resp["foo"]
      assert_equal "Foo/bar", resp["Content-Type"]
      assert_equal '{"a"=>"b"}', resp["bob"]
    }

  end


  def test_receives_http_ctx
    got_ctx = nil
    run_fdk (Proc.new {|context:, input:| got_ctx = context; nil}) {|client|
      resp = simple_req client, '{"message":"hello"}',
                        {
                                "Fn-Http-Request-Url" => "http://www.foo.bar.com/?baz=bar",
                                "Fn-Http-Method" => "PINCH",
                                "Fn-Http-H-X-Header" => "foo"
                        }

      puts got_ctx.http_context.headers
      assert_equal 200, resp.code.to_i
      assert_equal "http://www.foo.bar.com/?baz=bar", got_ctx.http_context.request_url
      assert_equal "PINCH", got_ctx.http_context.method
      assert_equal "foo", got_ctx.http_context.headers["x-header"]
    }
  end

  def test_sets_http_ctx
    run_fdk (Proc.new {|context:, input:|
      context.http_context.status_code = 302
      context.http_context.response_headers["Location"] = "http://example.com"
    }) {|client|
      resp = simple_req client

      assert_equal 200, resp.code.to_i
      assert_equal "302", resp["fn-http-status"]
      assert_equal "http://example.com", resp["fn-http-h-location"]

    }
  end

  def test_log_frame_header
    capout, caperr = with_captured_stdout_stderr {
      with_env({"FN_LOGFRAME_NAME" => "foo", "FN_LOGFRAME_HDR" => "Fn-Call-Id"}) {
        run_fdk (lambda {|context:, input:| "#{input} world"}) {|client|
          resp = simple_req client, "hello", {"fn-call-id" => "12345"}
          assert_equal 200, resp.code.to_i
        }
      }
    }
    assert_includes capout, "\nfoo=12345\n"
    assert_includes caperr, "\nfoo=12345\n"
  end


  def simple_req(client, body = "", headers = {})
    req = Net::HTTP::Post.new("/call")
    headers.each {|k, v|
      req[k] = v
    }
    req.body = body
    client.request(req)
  end

  def with_env (new_env = {})
    old_env = {}
    ENV.each {|k, v| old_env[k] = v}
    begin
      new_env.each {|k, v| ENV[k] = v}

      yield
    ensure
      ENV.replace old_env
    end

  end

  def with_captured_stdout_stderr
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    return $stdout.string, $stderr.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def run_fdk (handler)
    with_env {
      ENV["FN_FORMAT"] = "http-stream"
      Dir.mktmpdir {|dir|
        sockfile = "#{dir}/test.sock"
        ENV["FN_LISTENER"] = "unix:#{sockfile}"
        thr = Thread.new {
          begin
            FDK.handle(target: handler)
          rescue Exception => e
            STDERR.puts("error in main ", e)
          end
        }
        wait_for_socket sockfile
        client = NetX::HTTPUnix.new("unix://" + sockfile)
        yield client

        thr.kill
        thr.join
      }
    }
  end

  def wait_for_socket(file)
    for i in 0..100
      if File.exists? file
        return
      else
        sleep 0.1
      end
    end
    raise "No file found after 10 seconds"
  end
end
