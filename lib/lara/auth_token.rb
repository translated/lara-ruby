# frozen_string_literal: true

module Lara
  # JWT authentication token for API access
  class AuthToken
    attr_reader :token, :refresh_token

    def initialize(token, refresh_token)
      @token = token
      @refresh_token = refresh_token
    end

    def to_s
      token
    end
  end
end
