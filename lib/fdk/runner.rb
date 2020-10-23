# frozen_string_literal: true

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

require "webrick"
require "fileutils"
require "json"
require "set"

# Looks for call(context, input) function
# Executes it with input
# Responds with output
module FDK
  FDK_LOG_THRESHOLD = "FDK_LOG_THRESHOLD"
  FDK_LOG_DEBUG = 0
  FDK_LOG_DEFAULT = 1

  def self.log_threshold
    @log_threshold ||= ENV[FDK_LOG_THRESHOLD] ? ENV[FDK_LOG_THRESHOLD].to_i : FDK_LOG_DEFAULT
  end

  # Writes the entry to STDERR if the log_level >= log_threshold
  # If no log level is specified, 1 is assumed.
  def self.log(entry:, log_level: FDK_LOG_DEFAULT)
    warn(entry) if log_level >= log_threshold
  end

  def self.log_error(error:)
    log(entry: error.message)
    log(entry: error.backtrace.join("\n"), log_level: FDK_LOG_DEBUG)
  end

  def self.debug(msg)
    log(entry: msg, log_level: FDK_LOG_DEBUG)
  end

  def self.handle(target:)
    func = Function.new(function: target, format: ENV["FN_FORMAT"])
    Listener.new(url: ENV["FN_LISTENER"]).listen do |req, resp|
      func.call(request: req, response: resp)
    end
  end
end
