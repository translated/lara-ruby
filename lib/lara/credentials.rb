# frozen_string_literal: true

module Lara
  # Credentials for accessing the Lara API. A credentials object has two properties:
  # - access_key_id: The access key ID.
  # - access_key_secret: The access key secret.

  # IMPORTANT: Do not hard-code your access key ID and secret in your code. Always use environment variables or
  # a credentials file. Please note also that the access key secret is never sent directly via HTTP, but it is used to
  # sign the request. If you suspect that your access key secret has been compromised, you can revoke it in the Lara
  # dashboard.
  class Credentials
    # @!attribute [r] access_key_id
    #   @return [String] The access key ID.
    # @!attribute [r] access_key_secret
    #   @return [String] The access key secret.
    attr_reader :access_key_id, :access_key_secret

    # @param access_key_id [String] The access key ID.
    # @param access_key_secret [String] The access key secret.
    def initialize(access_key_id, access_key_secret)
      @access_key_id = access_key_id
      @access_key_secret = access_key_secret
    end
  end
end
