#!/usr/bin/env bash
set -ex
echo "Ruby Version"
ruby --version

(
 #run static code analysis
 rake rubocop
)

(
#run unit test cases
 rake test
)
