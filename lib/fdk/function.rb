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

module FDK
  # Function represents a function function or lambda
  class Function
    attr_reader :format, :function
    def initialize(function:, format:)
      raise "'#{format}' not supported in Ruby FDK." unless format == "http-stream"

      @format = format
      @function = function
    end

    def as_proc
      return function if function.respond_to?(:call)

      ->(context:, input:) { send(function, context: context, input: input) }
    end

    def call(request:, response:)
      Call.new(request: request, response: response).process(&as_proc)
    end
  end
end
