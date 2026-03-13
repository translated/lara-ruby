# frozen_string_literal: true

require "json"
require "base64"

module Lara
  # JWT authentication token for API access
  class AuthToken
    attr_reader :token, :refresh_token

    def initialize(token, refresh_token)
      @token = token
      @refresh_token = refresh_token
      @expires_at_ms = parse_expires_at_ms(token)
    end

    def to_s
      token
    end

    def token_expired?
      @expires_at_ms <= (Time.now.to_f * 1000).to_i + 5_000 # 5 seconds buffer
    end

    private

    def parse_expires_at_ms(token)
      return 0 if token.nil? || token.empty?

      parts = token.split(".")
      return 0 if parts.length != 3

      b64 = parts[1].tr("-_", "+/")
      b64 += "=" * (4 - (b64.length % 4)) if b64.length % 4 != 0

      exp = JSON.parse(Base64.decode64(b64))["exp"]
      return 0 unless exp.is_a?(Numeric)

      (exp * 1000).to_i
    rescue StandardError
      0
    end
  end
end
