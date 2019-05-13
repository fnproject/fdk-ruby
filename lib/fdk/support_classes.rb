# frozen_string_literal: true

module FDK
  # ParsedInput stores raw input and can parse it as
  # JSON (add extra formats as required)
  class ParsedInput
    attr_reader :raw

    def initialize(raw_input:)
      @raw = raw_input
    end

    def as_json
      @json ||= JSON.parse(raw)
    rescue JSON::ParserError
      @json = false
    end

    def parsed
      as_json || raw
    end
  end
end
