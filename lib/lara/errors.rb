# frozen_string_literal: true

require "json"

module Lara
  # Base SDK error.
  class LaraError < StandardError
    attr_reader :status_code

    def initialize(message, status_code = nil)
      super(message)
      @status_code = status_code
    end
  end

  # API error with HTTP status, type and message.
  class LaraApiError < LaraError
    attr_reader :type

    # Builds an error from an HTTP response with JSON body.
    # Supports both { "error": { "type": "...", "message": "..." } }
    # and { "type": "...", "message": "..." } response formats.
    def self.from_response(response)
      data = begin
        JSON.parse(response.body)
      rescue StandardError
        {}
      end
      error = data["error"] || data
      error_type = error["type"] || "UnknownError"
      error_message = error["message"] || "An unknown error occurred"
      new(response.status, error_type, error_message)
    end

    # @param status_code [Integer]
    # @param type [String]
    # @param message [String]
    def initialize(status_code, type, message)
      super("(HTTP #{status_code}) #{type}: #{message}", status_code)
      @type = type
      @message = message
    end
  end
end
