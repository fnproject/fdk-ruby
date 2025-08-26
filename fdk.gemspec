# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "fdk/version"

Gem::Specification.new do |s|
  s.name        = "fdk"
  s.version     = FDK::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Travis Reeder", "Ewan Slater", "Owen Cliffe"]
  s.email       = ["treeder@gmail.com", "ewan.slater@gmail.com", "owen.cliffe@oracle.com"]
  s.homepage    = "https://github.com/fnproject/fdk-ruby"
  s.summary     = "Ruby FDK for Fn Project"
  s.description = "Ruby Function Developer Kit for Fn Project."
  s.license     = "Apache-2.0"
  s.required_ruby_version = ">= 3.0"

  s.add_runtime_dependency "json", "~> 2.5", ">= 2.5.1"
  s.add_runtime_dependency "webrick", "~> 1.7", ">= 1.7.0"
  s.add_development_dependency "net_http_unix", "~> 0.2", ">= 0.2.2"
  s.add_development_dependency "rubocop", "~> 1.21"
  s.add_development_dependency "test-unit", "~> 2.0"
  s.add_runtime_dependency "uri", ">= 0.11.3", "< 2.0"
  s.add_runtime_dependency "resolv", ">= 0.3.1"

  s.files = Dir["Rakefile", "{bin,lib,man,test,spec}/**/*", "README*",
                "LICENSE*"]
end
